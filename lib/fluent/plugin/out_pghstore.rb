class Fluent::PgHStoreOutput < Fluent::BufferedOutput
  Fluent::Plugin.register_output('pghstore', self)

  config_param :database, :string
  config_param :table, :string, :default => 'hstore'
  config_param :host, :string, :default => 'localhost'
  config_param :port, :integer, :default => 5432
  config_param :user, :string, :default => nil
  config_param :password, :string, :default => nil

  def initialize
    super
    require 'pg'
  end

  def start
    super

    @conn = get_connection(@dbname, @host, @port, @user, @password)
  end

  def shutdown
    super

    @conn.close
  end
  
  # This method is called when an event is reached.
  # Convert event to a raw string.
  def format(tag, time, record)
    [tag, time, record].to_json + "\n"
  end

  # This method is called every flush interval. write the buffer chunk
  # to files or databases here.
  # 'chunk' is a buffer chunk that includes multiple formatted
  # events. You can use 'data = chunk.read' to get all events and
  # 'chunk.open {|io| ... }' to get IO object.
  def write(chunk)
    data = chunk.read
    print data
  end

  private

  INSERT_ARGUMENT = {:collect_on_error => true}
  BROKEN_DATA_KEY = '__broken_data'

  def generate_sql()
    
  end

  def operate(table, records)
    begin
      record_ids, error_records = table.insert(records, INSERT_ARGUMENT)
      if !@ignore_invalid_record and error_records.size > 0
        operate_invalid_records(table, error_records)
      end
    rescue Mongo::OperationFailure => e
      # Probably, all records of _records_ are broken...
      if e.error_code == 13066  # 13066 means "Message contains no documents"
        operate_invalid_records(table, records) unless @ignore_invalid_record
      else
        raise e
      end
    end
    records
  end


  def get_connection(dbname, host, port, user, password)
    return PG.connect(:dbname => dbname, :host => host, :port => port,
                      :user => user, :password => password)
  end

end
