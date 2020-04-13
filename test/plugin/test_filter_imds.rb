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
    to_return(status: 200, body: "{\"compute\":{\"azEnvironment\":\"AzurePublicCloud\",\"customData\":\"\",\"location\":\"eastus\",\"name\":\"fluentd-test2\",\"offer\":\"UbuntuServer\",\"osType\":\"Linux\",\"placementGroupId\":\"\",\"plan\":{\"name\":\"\",\"product\":\"\",\"publisher\":\"\"},\"platformFaultDomain\":\"0\",\"platformUpdateDomain\":\"0\",\"provider\":\"Microsoft.Compute\",\"publicKeys\":[],\"publisher\":\"Canonical\",\"resourceGroupName\":\"juelm-imds-fluentd\",\"resourceId\":\"/subscriptions/6748d8b1-3c1e-440e-8560-555f9747fe1f/resourceGroups/juelm-imds-fluentd/providers/Microsoft.Compute/virtualMachines/fluentd-test2\",\"sku\":\"18.04-LTS\",\"storageProfile\":{\"dataDisks\":[],\"imageReference\":{\"id\":\"\",\"offer\":\"UbuntuServer\",\"publisher\":\"Canonical\",\"sku\":\"18.04-LTS\",\"version\":\"latest\"},\"osDisk\":{\"caching\":\"ReadWrite\",\"createOption\":\"FromImage\",\"diffDiskSettings\":{\"option\":\"\"},\"diskSizeGB\":\"30\",\"encryptionSettings\":{\"enabled\":\"false\"},\"image\":{\"uri\":\"\"},\"managedDisk\":{\"id\":\"/subscriptions/6748d8b1-3c1e-440e-8560-555f9747fe1f/resourceGroups/JUELM-IMDS-FLUENTD/providers/Microsoft.Compute/disks/fluentd-test2_disk1_b2a49f76712c41aa850453e182f6c4e1\",\"storageAccountType\":\"Premium_LRS\"},\"name\":\"fluentd-test2_disk1_b2a49f76712c41aa850453e182f6c4e1\",\"osType\":\"Linux\",\"vhd\":{\"uri\":\"\"},\"writeAcceleratorEnabled\":\"false\"}},\"subscriptionId\":\"6748d8b1-3c1e-440e-8560-555f9747fe1f\",\"tags\":\"\",\"tagsList\":[],\"version\":\"18.04.202003170\",\"vmId\":\"a7ff7831-57cf-4fa6-9016-726d1c81dfdf\",\"vmScaleSetName\":\"\",\"vmSize\":\"Standard_B2s\",\"zone\":\"\"},\"network\":{\"interface\":[{\"ipv4\":{\"ipAddress\":[{\"privateIpAddress\":\"172.16.0.5\",\"publicIpAddress\":\"52.179.11.145\"}],\"subnet\":[{\"address\":\"172.16.0.0\",\"prefix\":\"24\"}]},\"ipv6\":{\"ipAddress\":[]},\"macAddress\":\"000D3A12811D\"}]}}", headers: {})
    d = create_driver(conf = '')
    d.run do
      d.feed("test1", @time, {"Matt says" => "Hello"})
    end
    assert_equal(d.filtered_records[0], {"Matt says" => "Hello"})
      
  end

end
