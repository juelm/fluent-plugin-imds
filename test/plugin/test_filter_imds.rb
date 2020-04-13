require "helper"
require "fluent/plugin/filter_imds.rb"
require 'webmock/test_unit'
WebMock.disable_net_connect!

class ImdsFilterTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
    @time = Fluent::Engine.now
  end

  # test "failure" do
  #   flunk
  # end

  #private

  def create_driver(conf)
    Fluent::Test::Driver::Filter.new(Fluent::Plugin::ImdsFilter).configure(conf)
  end

  test "test-to-see-that-filter-returns-correct-log" do
    stub_request(:get, "http://169.254.169.254/metadata/instance?api-version=2019-11-01").
    with(
      headers: {
  	  'Accept'=>'*/*',
  	  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
  	  'Host'=>'169.254.169.254',
  	  'Metadata'=>'true',
  	  'User-Agent'=>'Ruby'
      }).
    to_return(status: 200, body: "{\"compute\":{\"subscriptionId\":\"0000a0a0-0a0a-000a-0000-000a000aa0a\", \"location\":\"eastus\", \"resourceGroupName\":\"test-resource-group\"}}", headers: {})
    d = create_driver(conf = '')
    d.run do
      d.feed("test1", @time, {"Matt says" => "Hello"})
    end
    assert_equal(d.filtered_records[0]["Matt says"], "Hello")
    assert_equal(d.filtered_records[0]["subscriptionId"], "0000a0a0-0a0a-000a-0000-000a000aa0a")
    assert_equal(d.filtered_records[0]["region"], "eastus")
    assert_equal(d.filtered_records[0]["resourceGroup"], "test-resource-group")
      
  end

end
