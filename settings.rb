### Variable declarations - FEEL FREE TO EDIT THESE ###
DEFAULT_NUMBER_OF_NODES = 4
DEFAULT_RAM_IN_MB = 1024
DEFAULT_NUMBER_OF_CPUS = 1


### Edit these to allow other machines in your network to access the VMs

# Set to true to activate non-host access
#  make sure no one else will be impacted by this, as VMs will have forced ip that could collide
#  (typically you should be close to alone on the LAN, with a few machines, ie at home)
# alternatively set use_dhcp to true to avoid this (at the cost of not knowing the IP in advance)
PUBLIC_LAN = false
USE_DHCP = false

# Name of the host endpoint to serve as bridge to local network
#  (if not found vagrant will ask the user for each node)
DEFAULT_BRIDGE = "wlan0"

# Base for IP in public network. %d replaced by node number, eg "192.168.1.10%d" to get 101, 102, ...
#  (once again, be careful of potential ip collisions!)
PUBLIC_IP_BASE = "192.168.1.10%d"


### These settings should only be changed when adding or removing certain versions
IP_ADDRESSES = {
  "centos5"  => 110,
  "centos6"  => 111,
  "centos7"  => 112,
  "centos6u4" => 113,
  "debian7"  => 120,
  "debian8"  => 121,
  "opensuse11" => 130,
  "opensuse12" => 131,
  "ubuntu10" => 140,
  "ubuntu12" => 141,
  "ubuntu14" => 142,
  "windows"  => 150,

  "1.8.1"    => 51,
  "2.0.1"    => 56,
  "2.1.1"    => 61,
  "2.2.0"    => 65,
  "2.5.0"    => 70,
  "2.5.1"    => 71,
  "2.5.2"    => 72,
  "3.0.0"    => 80,
  "3.0.1"    => 81,
  "3.0.2"    => 82,
  "3.0.3"    => 83,
  "3.1.0"    => 90,
  "3.1.1"    => 91,
  "3.1.2"    => 92,
  "3.1.3"    => 93,
  "3.1.4"    => 94,
  "3.1.5"    => 95,
  "3.1.6-testing"    => 96,
  "4.0.0"    => 100,
  "4.1.0"    => 110,
  "4.1.1"    => 111,
  "4.5.0"    => 150,
  "4.5.0-testing" => 151,
  "cbdev"    => 200,
}

VAGRANT_BOXES = {
  "ubuntu10" => {"box_name" => "ubuntu-server-10044-x64-vbox4210",
                 "box_url"  => "http://puppet-vagrant-boxes.puppetlabs.com/ubuntu-server-10044-x64-vbox4210.box"
               },
  "ubuntu12" => "hashicorp/precise64",
  "ubuntu14" => "ubuntu/trusty64",
  "debian7"  => "cargomedia/debian-7-amd64-default",
  "centos5"  => {"box_name" => "centos5u8_x64",
                 "box_url"  => "https://dl.dropbox.com/u/17738575/CentOS-5.8-x86_64.box"
               },
  "centos6"  => {"box_name" => "puppetlabs/centos-6.6-64-puppet",
                 "box_VERSION" => "1.0.1"
                },
  "centos6u4" => {"box_name" => "hansode/centos-6.4-x86_64",
                  "box_VERSION" => "0.2.0"
                 },
  "centos7"  => { "box_name" => "puppetlabs/centos-7.0-64-puppet",
                  "box_VERSION" => "1.0.1"
                },
  "windows"  => "emyl/win2008r2",
  "opensuse11"  => "minesense/opensuse11.1",
  "opensuse12"   => {"box_name" => "opensuse-12.3-64",
                 "box_url" => "http://sourceforge.net/projects/opensusevagrant/files/12.3/opensuse-12.3-64.box/download",
                },
  "debian8"  => "lazyfrosch/debian-8-jessie-amd64-puppet",
}

# Couchbase Server Version download links
COUCHBASE_RELEASES = "http://packages.couchbase.com/releases"
LATEST_BUILDS = "http://latestbuilds.hq.couchbase.com"
SHERLOCK_BUILDS = "#{LATEST_BUILDS}/couchbase-server/sherlock"
WATSON_BUILD_NUM = "2601"
WATSON_BUILDS =  "https://s3.amazonaws.com/cb-support/watson-#{WATSON_BUILD_NUM}"
COUCHBASE_DOWNLOAD_LINKS = {
  "generic" => "#{COUCHBASE_RELEASES}/#{VERSION}/couchbase-server-enterprise_#{VERSION}_x86_64",
  "1.8.1" => "#{COUCHBASE_RELEASES}/#{VERSION}/couchbase-server-enterprise_x86_64_#{VERSION}",
  "2.0.1" => "#{COUCHBASE_RELEASES}/#{VERSION}/couchbase-server-enterprise_x86_64_#{VERSION}",
  "2.1.1" => "#{COUCHBASE_RELEASES}/#{VERSION}/couchbase-server-enterprise_x86_64_#{VERSION}",
  "2.2.0" => "#{COUCHBASE_RELEASES}/#{VERSION}/couchbase-server-enterprise_#{VERSION}_x86_64",
  "2.5.0" => {
              "centos5"  => "#{COUCHBASE_RELEASES}/#{VERSION}/couchbase-server-enterprise_#{VERSION}_x86_64_openssl098",
              "centos6"  => "#{COUCHBASE_RELEASES}/#{VERSION}/couchbase-server-enterprise_#{VERSION}_x86_64",
              "ubuntu10" => "#{COUCHBASE_RELEASES}/#{VERSION}/couchbase-server-enterprise_#{VERSION}_x86_64_openssl098",
              "ubuntu12" => "#{COUCHBASE_RELEASES}/#{VERSION}/couchbase-server-enterprise_#{VERSION}_x86_64",
  },
  "2.5.1" => {
              "centos5"  => "#{COUCHBASE_RELEASES}/#{VERSION}/couchbase-server-enterprise_#{VERSION}_x86_64_openssl098",
              "centos6"  => "#{COUCHBASE_RELEASES}/#{VERSION}/couchbase-server-enterprise_#{VERSION}_x86_64",
              "ubuntu10" => "#{COUCHBASE_RELEASES}/#{VERSION}/couchbase-server-enterprise_#{VERSION}_x86_64_openssl098",
              "ubuntu12" => "#{COUCHBASE_RELEASES}/#{VERSION}/couchbase-server-enterprise_#{VERSION}_x86_64",
  },
  "2.5.2" => {
              "centos5"  => "#{COUCHBASE_RELEASES}/#{VERSION}/couchbase-server-enterprise_#{VERSION}_x86_64_openssl098",
              "centos6"  => "#{COUCHBASE_RELEASES}/#{VERSION}/couchbase-server-enterprise_#{VERSION}_x86_64",
              "ubuntu10" => "#{COUCHBASE_RELEASES}/#{VERSION}/couchbase-server-enterprise_#{VERSION}_x86_64_openssl098",
              "ubuntu12" => "#{COUCHBASE_RELEASES}/#{VERSION}/couchbase-server-enterprise_#{VERSION}_x86_64",
  },
  "3.1.6-testing" => {
              "centos6"    => "#{LATEST_BUILDS}/couchbase-server-enterprise_centos6_x86_64_3.1.6-1895-rel",
              "debian7"    => "#{LATEST_BUILDS}/couchbase-server-enterprise_debian7_x86_64_3.1.6-1895-rel",
              "opensuse11" => "#{LATEST_BUILDS}/couchbase-server-enterprise_suse11_x86_64_3.1.6-1895-rel",
              "ubuntu12"   => "#{LATEST_BUILDS}/couchbase-server-enterprise_ubuntu_1204_x86_64_3.1.6-1895-rel",
  },
  "4.5.0-testing" => {
              "centos6"    => "#{WATSON_BUILDS}/couchbase-server-enterprise-4.5.0-#{WATSON_BUILD_NUM}-centos6.x86_64",
              "centos7"    => "#{WATSON_BUILDS}/couchbase-server-enterprise-4.5.0-#{WATSON_BUILD_NUM}-centos7.x86_64",
              "debian7"    => "#{WATSON_BUILDS}/couchbase-server-enterprise_4.5.0-#{WATSON_BUILD_NUM}-debian7_amd64",
              "debian8"    => "#{WATSON_BUILDS}/couchbase-server-enterprise_4.5.0-#{WATSON_BUILD_NUM}-debian8_amd64",
              "opensuse11" => "#{WATSON_BUILDS}/couchbase-server-enterprise-4.5.0-#{WATSON_BUILD_NUM}-suse11.x86_64",
              "opensuse12" => "#{WATSON_BUILDS}/couchbase-server-enterprise-4.5.0-#{WATSON_BUILD_NUM}-suse11.x86_64",
              "ubuntu12"   => "#{WATSON_BUILDS}/couchbase-server-enterprise_4.5.0-#{WATSON_BUILD_NUM}-ubuntu12.04_amd64",
              "ubuntu14"   => "#{WATSON_BUILDS}/couchbase-server-enterprise_4.5.0-#{WATSON_BUILD_NUM}-ubuntu14.04_amd64",
  },
  "centos6"    => "#{COUCHBASE_RELEASES}/#{VERSION}/couchbase-server-enterprise-#{VERSION}-centos6.x86_64",
  "centos7"    => "#{COUCHBASE_RELEASES}/#{VERSION}/couchbase-server-enterprise-#{VERSION}-centos7.x86_64",
  "debian7"    => "#{COUCHBASE_RELEASES}/#{VERSION}/couchbase-server-enterprise_#{VERSION}-debian7_amd64",
  "debian8"    => "#{COUCHBASE_RELEASES}/#{VERSION}/couchbase-server-enterprise_#{VERSION}-debian7_amd64",
  "opensuse11" => "#{COUCHBASE_RELEASES}/#{VERSION}/couchbase-server-enterprise-#{VERSION}-suse11.x86_64",
  "opensuse12" => "#{COUCHBASE_RELEASES}/#{VERSION}/couchbase-server-enterprise-#{VERSION}-suse11.x86_64",
  "ubuntu12"   => "#{COUCHBASE_RELEASES}/#{VERSION}/couchbase-server-enterprise_#{VERSION}-ubuntu12.04_amd64",
  "ubuntu14"   => "#{COUCHBASE_RELEASES}/#{VERSION}/couchbase-server-enterprise_#{VERSION}-ubuntu14.04_amd64",
}