require 'helper'

class PGHStoreOutputTest < Test::Unit::TestCase
  include Fluent::Test::Helpers

  def setup
    Fluent::Test.setup
  end

  HOST = "localhost"
  PORT = 5432
  DATABASE = "postgres"
  TABLE = "testtable"
  USER = ENV["PSQL_USER"] || "testuser"
  PASSWORD = ENV["PSQL_PASSWORD"] || "testpassword"
  CONFIG = %[
    database #{DATABASE}
    table #{TABLE}
    user #{USER}
    password #{PASSWORD}
  ]

  def create_driver(conf = CONFIG)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::PgHStoreOutput).configure(conf)
  end

  def test_configure
    d = create_driver

    assert_equal DATABASE, d.instance.database
    assert_equal HOST, d.instance.host
    assert_equal PORT, d.instance.port
    assert_equal USER, d.instance.user
    assert_equal PASSWORD, d.instance.password
  end

  def test_format
    d = create_driver
    with_connection(d) do |_conn|

      time = event_time("2011-01-02 13:14:15 UTC")
      d.run(default_tag: "test.input") do
        d.feed(time, {"a"=>1})
        d.feed(time, {"a"=>2})
      end
      formatted = d.formatted

      assert_equal [time, {"a"=>1}].to_msgpack, formatted[0]
      assert_equal [time, {"a"=>2}].to_msgpack, formatted[1]
    end
  end

  def test_write
    d = create_driver
    with_connection(d) do |conn|
      time = event_time("2011-01-02 13:14:15 UTC")
      d.run(default_tag: "test.input") do
        d.feed(time, {"a"=>1})
        d.feed(time, {"a"=>2})
      end

      wait_data(conn)

      res = conn.exec("select * from #{TABLE}")[0]
      assert_equal "{test,input}", res["tag"]
      assert_equal Time.at(time), Time.parse(res["time"])
      assert_equal "\"a\"=>\"1\"", res["record"]
    end
  end

  def ensure_connection
    conn = nil
    assert_nothing_raised do
      conn = PGconn.new(:dbname => DATABASE, :host => HOST, :port => PORT, :user => USER, :password => PASSWORD)
    end
    conn
  end

  def with_connection(driver, &block)
    conn = ensure_connection
    register_hstore(conn) rescue nil # suppress Exception
    create_test_table(driver, conn)
    begin
      block.call(conn)
    ensure
      drop_test_table(conn)
      unregister_hstore(conn)
      conn.close
    end
  end

  def register_hstore(conn)
    conn.exec("CREATE EXTENSION hstore;")
  end

  def unregister_hstore(conn)
    conn.exec("DROP EXTENSION hstore;")
  end

  def create_test_table(driver, conn)
    conn.exec(driver.instance.table_schema("#{TABLE}"))
  end

  def drop_test_table(conn)
    conn.exec("DROP TABLE #{TABLE}")
  end

  def wait_data(conn)
    10.times do
      res = conn.exec "select count(*) from #{TABLE}"
      return if res.getvalue(0,0).to_i > 0
      sleep 0.2
    end
    raise "Inserting records have not been finished correctly"
  end
end
