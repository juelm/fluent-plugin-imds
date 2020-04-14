require "helper"
require "fluent/plugin/filter_imds.rb"
require 'webmock/test_unit'
WebMock.disable_net_connect!

class ImdsFilterTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
    @time = Fluent::Engine.now
  end

  CONFIG = %[
    containerIdInput "\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000a0a000a0-0000-0a00-aaa0-aaaa00aa0a00\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000NextKVPKey\u0000\u0000\u0000\u0000\u0000NextKVPValue\u0000\u0000\u0000\u0000\u0000"
  ]

  def create_driver(conf = CONFIG)
    Fluent::Test::Driver::Filter.new(Fluent::Plugin::ImdsFilter).configure(conf)
  end

  test "test-to-see-that-filter-returns-correct-message-and-imds-data" do
    stub_request(:get, "http://169.254.169.254/metadata/instance?api-version=2019-11-01").
    with(
      headers: {
  	  'Accept'=>'*/*',
  	  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
  	  'Host'=>'169.254.169.254',
  	  'Metadata'=>'true',
  	  'User-Agent'=>'Ruby'
      }).
    to_return(status: 200, body: "{\"compute\":{\"subscriptionId\":\"0000a0a0-0a0a-000a-0000-000a000aa0a\", \"location\":\"eastus\", \"resourceGroupName\":\"test-resource-group\", \"name\":\"test-vm\", \"vmSize\":\"Standard_B2s\", \"vmId\":\"a0aa0000-00aa-0aa0-0000-000a0a00aaaa\", \"placementGroupId\":\"\"}}", headers: {})
    d = create_driver()
    d.run do
      d.feed("test1", @time, {"Matt says" => "Hello"})
    end
    assert_equal(d.filtered_records[0]["Matt says"], "Hello")
    assert_equal(d.filtered_records[0]["subscriptionId"], "0000a0a0-0a0a-000a-0000-000a000aa0a")
    assert_equal(d.filtered_records[0]["region"], "eastus")
    assert_equal(d.filtered_records[0]["resourceGroup"], "test-resource-group")
    assert_equal(d.filtered_records[0]["vmName"], "test-vm")
    assert_equal(d.filtered_records[0]["vmSize"], "Standard_B2s")
    assert_equal(d.filtered_records[0]["vmId"], "a0aa0000-00aa-0aa0-0000-000a0a00aaaa")
    assert_equal(d.filtered_records[0]["placementGroup"], "") 
    assert_equal(d.filtered_records[0]["containerID"], "a0a000a0-0000-0a00-aaa0-aaaa00aa0a00")
  end

  test "test-to-see-that-filter-returns-error-message-on-http-failure" do
    error = 404
    message = Net::HTTPResponse::CODE_TO_OBJ['404']
    stub_request(:get, "http://169.254.169.254/metadata/instance?api-version=2019-11-01").
    with(
      headers: {
  	  'Accept'=>'*/*',
  	  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
  	  'Host'=>'169.254.169.254',
  	  'Metadata'=>'true',
  	  'User-Agent'=>'Ruby'
      }).
    to_return(status: 404, body: "{\"compute\":{\"subscriptionId\":\"0000a0a0-0a0a-000a-0000-000a000aa0a\", \"location\":\"eastus\", \"resourceGroupName\":\"test-resource-group\", \"name\":\"test-vm\", \"vmSize\":\"Standard_B2s\", \"vmId\":\"a0aa0000-00aa-0aa0-0000-000a0a00aaaa\", \"placementGroupId\":\"\"}}", headers: {})
    d = create_driver()
    d.run do
      d.feed("test1", @time, {"Matt says" => "Hello"})
    end
    assert_equal(d.filtered_records[0]["Matt says"], "Hello")
    assert_equal(d.filtered_records[0]["IMDSError"], "IMDS Request failed with error #{error}: #{message}")
  end

end
