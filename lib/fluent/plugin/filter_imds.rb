#
# Copyright 2020- TODO: Write your name
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "fluent/plugin/filter"
require 'net/http'
require 'uri'

module Fluent
  module Plugin
    class ImdsFilter < Fluent::Plugin::Filter
      Fluent::Plugin.register_filter("imds", self)

      config_param :test, :bool, :default => false

      def stripKVPValue(unstrippedString)
        reachedStartOfContainerId = false
        containerID = ""
        unstrippedString.each_char {|c|
            if c == "\u0000"
                if reachedStartOfContainerId
                    return containerID
                end
            else
                if !reachedStartOfContainerId
                    reachedStartOfContainerId = true
                end
                containerID += c
            end
        }
        containerID
      end

      def filter(tag, time, record)

        if(@test)
          return record
        end

        uri = URI.parse("http://169.254.169.254/metadata/instance?api-version=2019-11-01")
        request = Net::HTTP::Get.new(uri)
        request["Metadata"] = "true"

        req_options = {
          use_ssl: uri.scheme == "https",
        }

        response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
        end

        if response == Net::HTTPSuccess 
          data = JSON.parse(response.body)
        else
          #Is there anything else we should include if IMDS fails.  Maybe VMName from kvp_pool?
          record["IMDS Error"] = "IMDS Request failed"
          return record
        end

        #data = JSON.parse(response.body)

        record["subscriptionId"] = data["compute"]["subscriptionId"]
        record["region"] = data["compute"]["location"]
        record["resourceGroup"] = data["compute"]["resourceGroupName"]
        record["vmName"] = data["compute"]["name"]
        record["vmSize"] = data["compute"]["vmSize"]
        record["vmId"] = data["compute"]["vmId"]
        record["placementGroup"] = data["compute"]["placementGroupId"]
        unstrippedDistro = `lsb_release -si`
        record["distro"] = unstrippedDistro.strip
        unstrippedVersion = `lsb_release -sr`
        record["distroVersion"] = unstrippedVersion.strip
        unstrippedKernel = `uname -r`
        record["kernelVersion"] = unstrippedKernel.strip
        unstrippedContainerId = `cat /var/lib/hyperv/.kvp_pool_3 | sed -e 's/^.*VirtualMachineName//'      `
        strippedContainerId = stripKVPValue(unstrippedContainerId)
        record["containerID"] = strippedContainerId

        record
      end
    end
  end
end
