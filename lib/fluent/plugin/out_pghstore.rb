class Fluent::PgHStoreOutput < Fluent::BufferedOutput
  Fluent::Plugin.register_output('pghstore', self)

  config_param :database, :string
  config_param :table, :string, :default => 'fluentd_store'
  config_param :host, :string, :default => 'localhost'
  config_param :port, :integer, :default => 5432
  config_param :user, :string, :default => nil
  config_param :password, :string, :default => nil, :secret => true

  config_param :table_option, :string, :default => nil

  def initialize
    super
    require 'pg'
  end

  def start
    super

    create_table(@table) unless table_exists?(@table)
  end

  def shutdown
    super

    if @conn != nil and @conn.finished?() == false
      conn.close()
    end
  end
  
  def format(tag, time, record)
    [tag, time, record].to_msgpack
  end

  def write(chunk)
    conn = get_connection()
    return if conn == nil  # TODO: chunk will be dropped. should retry?

    chunk.msgpack_each {|(tag, time_str, record)|
      sql = generate_sql(conn, tag, time_str, record)
      begin
        conn.exec(sql)
      rescue PGError => e 
        $log.error "PGError: " + e.message  # dropped if error
      end
    }

    conn.close()
  end

  private

  def generate_sql(conn, tag, time, record)
    kv_list = []
    record.each {|(key,value)|
      kv_list.push("\"#{conn.escape_string(key.to_s)}\" => \"#{conn.escape_string(value.to_s)}\"")
    }

    tag_list = tag.split(".")
    tag_list.map! {|t| "'" + t + "'"}

    sql =<<"SQL"
INSERT INTO #{@table} (tag, time, record) VALUES
(ARRAY[#{tag_list.join(",")}], '#{Time.at(time)}'::TIMESTAMP WITH TIME ZONE, E'#{kv_list.join(",")}');
SQL

    return sql
  end

  def get_connection()
    if @conn != nil and @conn.finished?() == false
        return @conn  # connection is alived
    end

    begin
      if @user
        @conn = PG.connect(:dbname => @database, :host => @host, :port => @port,
                           :user => @user, :password => @password)
      else
        @conn = PG.connect(:dbname => @database, :host => @host, :port => @port)
      end
    rescue PGError => e
      $log.error "Error: could not connect database:" + @database
      return nil
    end

    return @conn

  end

  def table_exists?(table)
    sql =<<"SQL"
SELECT COUNT(*) FROM pg_tables WHERE tablename = '#{table}';
SQL
    conn = get_connection()
    raise "Could not connect the database at startup. abort." if conn == nil
    res = conn.exec(sql)
    conn.close
    if res[0]["count"] == "1"
      return true
    else
      return false
    end
  end

  def create_table(tablename)
    sql =<<"SQL"
CREATE TABLE #{tablename} (
  tag TEXT[],
  time TIMESTAMP WITH TIME ZONE,
  record HSTORE
);
SQL

    sql += @table_option if @table_option

    conn = get_connection()
    raise "Could not connect the database at create_table. abort." if conn == nil

    begin
      conn.exec(sql) 
    rescue PGError => e
      $log.error "Error at create_table:" + e.message
      $log.error "SQL:" + sql
    end
    conn.close

    $log.warn "table #{tablename} was not exist. created it."
  end

end
