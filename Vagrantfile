# System for quickly and painlessly provisioning Couchbase Server virtual machines across multiple Couchbase versions and OS's.
# See README.md for usage instructions

### Variable declarations - FEEL FREE TO EDIT THESE ###
begin
ip_addresses = { # Values for both OS's and Couchbase versions that are cat'd together to form a full ip address
  "ubuntu10" => "1",
  "ubuntu12" => "2",
  "ubuntu14" => "4",
  "centos5"  => "5",
  "centos6"  => "6",
  "windows"  => "7",
  "1.8.1"    => "8",
  "2.0.1"    => "2",
  "2.5.0"    => "5",
  "2.5.1"    => "1",
  "3.0.0-973-rel" => "3",
  "???"      => "9"
}
vagrant_boxes = { # Vagrant Cloud base boxes for each operating system
  "ubuntu10" => {"box_name" => "ubuntu-server-10044-x64-vbox4210",
                 "box_url"  => "http://puppet-vagrant-boxes.puppetlabs.com/ubuntu-server-10044-x64-vbox4210.box"
               },
  "ubuntu12" => "hashicorp/precise64",
  "ubuntu14" => "ubuntu/trusty64",
  "centos5"  => {"box_name" => "centos5u8_x64",
                 "box_url"  => "https://dl.dropbox.com/u/17738575/CentOS-5.8-x86_64.box"
               },
  "centos6"  => "puppetlabs/centos-6.5-64-puppet",
  "centos7"  => "hfm4/centos7",
  "windows"  => "emyl/win2008r2",
}

# Collect the names of the working directory and its parent (os and cb version)
operating_system = File.basename(Dir.getwd)
if (defined?(version)).nil?
  version  = File.basename(File.expand_path('..'))
end

# Couchbase Server Version download links
couchbase_download_links = {
  "2.0.1" => "http://packages.couchbase.com/releases/2.0.1/couchbase-server-enterprise_x86_64_2.0.1",
  "2.5.1" => {"ubuntu10" => "http://packages.couchbase.com.s3.amazonaws.com/releases/2.5.1/couchbase-server-enterprise_2.5.1_x86_64_openssl098"},
  "3.0.0-973-rel" => {"centos6"  => "http://packages.northscale.com/latestbuilds/3.0.0/couchbase-server-enterprise_centos6_x86_64_#{version}",
                      "ubuntu10" => "http://packages.northscale.com/latestbuilds/3.0.0/couchbase-server-enterprise_x86_64_#{version}",
                      "ubuntu12" => "http://packages.northscale.com/latestbuilds/3.0.0/couchbase-server-enterprise_ubuntu_1204_x86_64_#{version}"
                      }
}

default_number_of_nodes = 4

### DO NOT EDIT BELOW THIS LINE ###

# Number of nodes to provision
unless ENV['VAGRANT_NODES'].nil? || ENV['VAGRANT_NODES'] == 0
  num_nodes = ENV['VAGRANT_NODES'].to_i
else
  num_nodes = default_number_of_nodes
end

# Check to see if a custom download location has been given, if not use a default value (2.5.0 style)
if couchbase_download_links[version][operating_system].length > 1
    url = couchbase_download_links[version][operating_system]
elsif couchbase_download_links[version] > 1
    url = couchbase_download_links[version]
else
  url= "http://packages.couchbase.com/releases/#{version}/couchbase-server-enterprise_#{version}_x86_64"
end

# Check to see if a custom ip address has been given, if not generate one
if (defined?(ip)).nil?
  base = "192.168."
  ip_address = base + ip_addresses[operating_system] + ip_addresses[version] + ".10%d"
end

# Check to see if the vagrant command given was 'up', if so print a handy dialogue
if ARGV[0] == "up"
  puts "\e[32m=== Created #{num_nodes} node(s) on #{operating_system} and cb version #{version} ==="
end

### Start the vagrant configuration ###
Vagrant.configure("2") do |config|

  # Define Number of RAM for each node
  config.vm.provider :virtualbox do |v|
    v.customize ["modifyvm", :id, "--memory", 1024]
  end

  # Define the vagrant box download location
  if !(vagrant_boxes[operating_system]["box_url"].nil?)
    config.vm.box_url = vagrant_boxes[operating_system]["box_url"]
  end

  # Define the vagrant box name
  if !(vagrant_boxes[operating_system]["box_name"].nil?)
    box_name = vagrant_boxes[operating_system]["box_name"]
  else
    box_name = vagrant_boxes[operating_system]
  end

  # Check to see if the VM is not running Windows and provision with puppet
  if !(operating_system.include?("win"))
    # Provision the server itself with puppet
    config.vm.provision "puppet" do |puppet|
      puppet.manifests_path = "../../" # Define a custom location and name for the puppet file
      puppet.manifest_file = "puppet.pp"
      puppet.facter = { # Pass variables to puppet
        "version" => version, # Couchbase Server version
        "url" => url, # Couchbase download location
      }
    end
  end

  # Provision Config for each of the nodes
  1.upto(num_nodes) do |num|
    config.vm.define "node#{num}" do |node|
      node.vm.box = box_name
      node.vm.network :private_network, :ip => ip_address % num
      node.vm.provider "virtualbox" do |v|
        v.name = "Couchbase Server #{version} #{operating_system.gsub '/', '_'} Node #{num}"
        if(operating_system.include?("win")) # If the VM is running Windows it will start with a GUI
          v.gui = true
        end
      end
    end
  end
end
rescue
end
