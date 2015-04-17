# System for quickly and painlessly provisioning Couchbase Server virtual machines across multiple Couchbase versions and OS's.
# See README.md for usage instructions

### Variable declarations - FEEL FREE TO EDIT THESE ###
begin
ip_addresses = { # Values for both OS's and Couchbase versions that are cat'd together to form a full ip address
  "unused"   => 0, # Skip 0 to avoid colliding with commonly used 192.168.[01].x
  "centos5"  => 1,
  "centos6"  => 2,
  "centos7"  => 3,
  "debian7"  => 4,
  "ubuntu10" => 5,
  "ubuntu12" => 6,
  "ubuntu14" => 7,
  "windows"  => 8,
  "sles11"   => 9,

  "1.8.1"    => 0,
  "2.0.1"    => 1,
  "2.1.1"    => 2,
  "2.2.0"    => 3,
  "2.5.0"    => 4,
  "2.5.1"    => 5,
  "2.5.2"    => 6,
  "3.0.0"    => 7,
  "3.0.1"    => 8,
  "3.0.2"    => 9,
  "3.0.3"    => 10,
  "4.0.0-pre-alpha" => 14,
  "cbdev"    => 15,
}
vagrant_boxes = { # Vagrant Cloud base boxes for each operating system
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
                 "box_url"  => "puppetlabs/centos-6.6-64-puppet",
                },
  "centos7"  => "hfm4/centos7",
  "windows"  => "emyl/win2008r2",
  "sles11"   => {"box_name" => "opensuse-12.3-64",
                 "box_url" => "http://sourceforge.net/projects/opensusevagrant/files/12.3/opensuse-12.3-64.box/download",
                },
}

# Collect the names of the working directory and its parent (os and cb version)
operating_system = File.basename(Dir.getwd)
version  ||= File.basename(File.expand_path('..'))

# Couchbase Server Version download links
couchbase_download_links = {
  "1.8.1" => "http://packages.couchbase.com/releases/1.8.1/couchbase-server-enterprise_x86_64_1.8.1",
  "2.0.1" => "http://packages.couchbase.com/releases/2.0.1/couchbase-server-enterprise_x86_64_2.0.1",
  "2.1.1" => "http://packages.couchbase.com.s3.amazonaws.com/releases/2.1.1/couchbase-server-enterprise_x86_64_2.1.1",
  "2.5.1" => {"ubuntu10" => "http://packages.couchbase.com.s3.amazonaws.com/releases/2.5.1/couchbase-server-enterprise_2.5.1_x86_64_openssl098"},
  "2.5.2" => {"ubuntu10" => "http://packages.couchbase.com/releases/2.5.2/couchbase-server-enterprise_2.5.2_x86_64_openssl098"},
  "3.0.0" => {"ubuntu12" => "http://packages.couchbase.com/releases/3.0.0/couchbase-server-enterprise_3.0.0-ubuntu12.04_amd64",
              "centos6"  => "http://packages.couchbase.com/releases/3.0.0/couchbase-server-enterprise-3.0.0-centos6.x86_64",
              "centos7"  => "http://packages.couchbase.com/releases/3.0.0/couchbase-server-enterprise-3.0.0-centos6.x86_64",
              "debian7"  => "http://packages.couchbase.com/releases/3.0.0/couchbase-server-enterprise_3.0.0-debian7_amd64"
             },
  "3.0.1" => {"ubuntu12" => "http://packages.couchbase.com/releases/3.0.1/couchbase-server-enterprise_3.0.1-ubuntu12.04_amd64",
              "centos6"  => "http://packages.couchbase.com/releases/3.0.1/couchbase-server-enterprise-3.0.1-centos6.x86_64",
              "centos7"  => "http://packages.couchbase.com/releases/3.0.1/couchbase-server-enterprise-3.0.1-centos6.x86_64",
              "debian7"  => "http://packages.couchbase.com/releases/3.0.1/couchbase-server-enterprise_3.0.1-debian7_amd64"
             },
  "3.0.2" => {"ubuntu12" => "http://packages.couchbase.com/releases/3.0.2/couchbase-server-enterprise_3.0.2-ubuntu12.04_amd64",
              "centos6"  => "http://packages.couchbase.com/releases/3.0.2/couchbase-server-enterprise-3.0.2-centos6.x86_64",
              "centos7"  => "http://packages.couchbase.com/releases/3.0.2/couchbase-server-enterprise-3.0.2-centos6.x86_64",
              "debian7"  => "http://packages.couchbase.com/releases/3.0.2/couchbase-server-enterprise_3.0.2-debian7_amd64"
             },
  "3.0.3" => {"ubuntu12" => "http://packages.couchbase.com/releases/3.0.3/couchbase-server-enterprise_3.0.3-ubuntu12.04_amd64",
              "centos6"  => "http://packages.couchbase.com/releases/3.0.3/couchbase-server-enterprise-3.0.3-centos6.x86_64",
              "centos7"  => "http://packages.couchbase.com/releases/3.0.3/couchbase-server-enterprise-3.0.3-centos6.x86_64",
              "debian7"  => "http://packages.couchbase.com/releases/3.0.3/couchbase-server-enterprise_3.0.3-debian7_amd64"
             },
  "4.0.0-pre-alpha" => {
              "centos6"  => "http://latestbuilds.hq.couchbase.com/couchbase-server/sherlock/1891/couchbase-server-enterprise-4.0.0-1891-centos6.x86_64",
              "centos7"  => "http://latestbuilds.hq.couchbase.com/couchbase-server/sherlock/1891/couchbase-server-enterprise-4.0.0-1891-centos7.x86_64",
              "debian7"  => "http://latestbuilds.hq.couchbase.com/couchbase-server/sherlock/1891/couchbase-server-enterprise_4.0.0-1891-debian7_amd64",
              "sles11"   => "http://latestbuilds.hq.couchbase.com/couchbase-server/sherlock/1891/couchbase-server-enterprise-4.0.0-1891-opensuse11.3.x86_64",
              "ubuntu12" => "http://latestbuilds.hq.couchbase.com/couchbase-server/sherlock/1891/couchbase-server-enterprise_4.0.0-1891-ubuntu12.04_amd64",
              "ubuntu14" => "http://latestbuilds.hq.couchbase.com/couchbase-server/sherlock/1891/couchbase-server-enterprise_4.0.0-1891-ubuntu14.04_amd64",
             },
}

default_number_of_nodes = 4
default_RAM_in_MB = 1024
default_number_of_cpus = 1

### DO NOT EDIT BELOW THIS LINE

# Number of nodes to provision
unless ENV['VAGRANT_NODES'].nil? || ENV['VAGRANT_NODES'] == 0
  num_nodes = ENV['VAGRANT_NODES'].to_i
else
  if num_nodes.nil?
    num_nodes = default_number_of_nodes
  end
end

unless ENV['VAGRANT_CPUS'].nil? || ENV['VAGRANT_CPUS'] == 0
  num_cpus = ENV['VAGRANT_CPUS'].to_i
else
  num_cpus = default_number_of_cpus
end

unless ENV['VAGRANT_RAM'].nil? || ENV['VAGRANT_RAM'] == 0
  ram_in_MB = ENV['VAGRANT_RAM'].to_i
else
  ram_in_MB = default_RAM_in_MB
end

# Check to see if a custom download location has been given, if not use a default value (2.5.0 style)
if couchbase_download_links.has_key?(version)
  if couchbase_download_links[version].is_a?(String)
    url = couchbase_download_links[version]
  elsif couchbase_download_links[version].has_key?(operating_system)
    url = couchbase_download_links[version][operating_system]
  end
end
url ||= "http://packages.couchbase.com/releases/#{version}/couchbase-server-enterprise_#{version}_x86_64"

puppet_location ||= "../.."

# Check to see if a custom ip address has been given, if not generate one
if (defined?(ip)).nil?
  ip_address = "192.168." + String((ip_addresses[operating_system] << 4) + ip_addresses[version]) + ".10%d"
end

# Check to see if the vagrant command given was 'up', if so print a handy dialogue
if ARGV[0] == "up" && !ARGV[1]
  puts "\e[32m=== Upping #{num_nodes} node(s) on #{operating_system} and cb version #{version} ==="
end

### Start the vagrant configuration ###
Vagrant.configure("2") do |config|

  # Define VM properties for each node (for both virtualbox and
  # libvirt providers).
  config.vm.provider :virtualbox do |vb|
    vb.memory = ram_in_MB
    vb.cpus = num_cpus
    vb.customize ["modifyvm", :id, "--ioapic", "on"]
  end
  config.vm.provider :libvirt do |libvirt|
    libvirt.memory = ram_in_MB
    libvirt.cpus = num_cpus
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
      puppet.manifests_path = puppet_location # Define a custom location and name for the puppet file
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
      # Postfix a random value to hostname to uniquify it.
      node.vm.provider "libvirt" do |v|
        v.random_hostname = true
      end
    end
  end

  if ARGV[0] == "up" && !ARGV[1]
    puts "\e[32m=== Upping #{num_nodes} node(s) on IPs #{ip_address.sub('%d','')}{1..#{num_nodes}} ==="
  end

end
rescue
end
