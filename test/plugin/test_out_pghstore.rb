require 'helper'

class PGHStoreOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    database "testdb"
    table "testtable"
    user "testuser"
    password "testpassword"
  ]

  def create_driver(conf = CONFIG, tag='test.input')
    Fluent::Test::BufferedOutputTestDriver.new(Fluent::PgHStoreOutput, tag).configure(conf)
  end

  def test_configure
  end

  def test_format
    d = create_driver

    # time = Time.parse("2011-01-02 13:14:15 UTC").to_i
    # d.emit({"a"=>1}, time)
    # d.emit({"a"=>2}, time)

    # d.expect_format %[2011-01-02T13:14:15Z\ttest\t{"a":1}\n]
    # d.expect_format %[2011-01-02T13:14:15Z\ttest\t{"a":2}\n]

    # d.run
  end

  def test_write
    d = create_driver

    # time = Time.parse("2011-01-02 13:14:15 UTC").to_i
    # d.emit({"a"=>1}, time)
    # d.emit({"a"=>2}, time)

  end

end
