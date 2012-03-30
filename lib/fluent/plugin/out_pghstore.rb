class Fluent::PgHStoreOutput < Fluent::BufferedOutput
  Fluent::Plugin.register_output('pghstore', self)

  config_param :database, :string
  config_param :table, :string, :default => 'fluentd_store'
  config_param :host, :string, :default => 'localhost'
  config_param :port, :integer, :default => 5432
  config_param :user, :string, :default => nil
  config_param :password, :string, :default => nil

  config_param :table_option, :string, :default => nil

  def initialize
    super
    require 'pg'
  end

  def start
    super

    @conn = get_connection(@database, @host, @port, @user, @password)

    create_table(@table) unless table_exists?(@table)

  end

  def shutdown
    super

    @conn.close
  end
  
  def format(tag, time, record)
    [tag, time, record].to_msgpack
  end

  def write(chunk)
    chunk.msgpack_each {|(tag, time_str, record)|
      sql = generate_sql(tag, time_str, record)
      @conn.exec(sql)
    }
  end

  private

  def generate_sql(tag, time, record)
    kv_list = []
    record.each {|(key,value)|
      begin
        v = Integer(value)
      rescue ArgumentError => e
        kv_list.push("#{key} => \"#{value}\"")  # might be string
      else
        kv_list.push("#{key} => #{value}")
      end
    }

    sql =<<"SQL"
INSERT INTO #{@table} (tag, time, record) VALUES
('#{tag}', '#{Time.at(time)}'::TIMESTAMP WITH TIME ZONE, '#{kv_list.join(",")}');
SQL
    return sql
  end

  def get_connection(dbname, host, port, user, password)
    if user
      return PG.connect(:dbname => dbname, :host => host, :port => port,
                        :user => user, :password => password)
    else
      return PG.connect(:dbname => dbname, :host => host, :port => port)
    end
  end

  def table_exists?(table)
    sql =<<"SQL"
SELECT COUNT(*) FROM pg_tables WHERE tablename = '#{table}';
SQL
    res = @conn.exec(sql)
    if res[0]["count"] == "1"
      return true
    else
      return false
    end
  end

  def create_table(tablename)
    sql =<<"SQL"
CREATE TABLE #{tablename} (
  tag TEXT,
  time TIMESTAMP WITH TIME ZONE,
  record HSTORE
);
SQL

    sql += @table_option if @table_option

    @conn.exec(sql)

    $log.warn "#{tablename} table is not exists. created."
  end

end
