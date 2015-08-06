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
  "opensuse11"   => 9,
  "debian8-unsupported"  => 10,
  "opensuse12-unsupported" => 11,

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
  "3.1.0"    => 11,
  "4.0.0-beta" => 12,
  "4.0.0-dp" => 13,
  "4.0.0-testing" => 14,
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
  "opensuse11"  => "minesense/opensuse11.1",
  "opensuse12-unsupported"   => {"box_name" => "opensuse-12.3-64",
                 "box_url" => "http://sourceforge.net/projects/opensusevagrant/files/12.3/opensuse-12.3-64.box/download",
                },
  "debian8-unsupported"  => "lazyfrosch/debian-8-jessie-amd64-puppet",
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
              "debian7"  => "http://packages.couchbase.com/releases/3.0.0/couchbase-server-enterprise_3.0.0-debian7_amd64",
              "debian8-unsupported"  => "http://packages.couchbase.com/releases/3.0.0/couchbase-server-enterprise_3.0.0-debian7_amd64",
             },
  "3.0.1" => {"ubuntu12" => "http://packages.couchbase.com/releases/3.0.1/couchbase-server-enterprise_3.0.1-ubuntu12.04_amd64",
              "centos6"  => "http://packages.couchbase.com/releases/3.0.1/couchbase-server-enterprise-3.0.1-centos6.x86_64",
              "centos7"  => "http://packages.couchbase.com/releases/3.0.1/couchbase-server-enterprise-3.0.1-centos6.x86_64",
              "debian7"  => "http://packages.couchbase.com/releases/3.0.1/couchbase-server-enterprise_3.0.1-debian7_amd64",
              "debian8-unsupported"  => "http://packages.couchbase.com/releases/3.0.1/couchbase-server-enterprise_3.0.1-debian7_amd64",
             },
  "3.0.2" => {"ubuntu12" => "http://packages.couchbase.com/releases/3.0.2/couchbase-server-enterprise_3.0.2-ubuntu12.04_amd64",
              "centos6"  => "http://packages.couchbase.com/releases/3.0.2/couchbase-server-enterprise-3.0.2-centos6.x86_64",
              "centos7"  => "http://packages.couchbase.com/releases/3.0.2/couchbase-server-enterprise-3.0.2-centos6.x86_64",
              "debian7"  => "http://packages.couchbase.com/releases/3.0.2/couchbase-server-enterprise_3.0.2-debian7_amd64",
              "debian8-unsupported"  => "http://packages.couchbase.com/releases/3.0.2/couchbase-server-enterprise_3.0.2-debian7_amd64",
             },
  "3.0.3" => {"ubuntu12" => "http://packages.couchbase.com/releases/3.0.3/couchbase-server-enterprise_3.0.3-ubuntu12.04_amd64",
              "centos6"  => "http://packages.couchbase.com/releases/3.0.3/couchbase-server-enterprise-3.0.3-centos6.x86_64",
              "centos7"  => "http://packages.couchbase.com/releases/3.0.3/couchbase-server-enterprise-3.0.3-centos6.x86_64",
              "debian7"  => "http://packages.couchbase.com/releases/3.0.3/couchbase-server-enterprise_3.0.3-debian7_amd64",
              "debian8-unsupported"  => "http://packages.couchbase.com/releases/3.0.3/couchbase-server-enterprise_3.0.3-debian7_amd64",
             },
  "3.1.0" => {"ubuntu12" => "http://packages.couchbase.com/releases/3.1.0/couchbase-server-enterprise_3.1.0-ubuntu12.04_amd64",
              "centos6"  => "http://packages.couchbase.com/releases/3.1.0/couchbase-server-enterprise-3.1.0-centos6.x86_64",
              "centos7"  => "http://packages.couchbase.com/releases/3.1.0/couchbase-server-enterprise-3.1.0-centos6.x86_64",
              "debian7"  => "http://packages.couchbase.com/releases/3.1.0/couchbase-server-enterprise_3.1.0-debian7_amd64",
              "debian8-unsupported"  => "http://packages.couchbase.com/releases/3.1.0/couchbase-server-enterprise_3.1.0-debian7_amd64",
             },
  "4.0.0-beta" => {
              "centos6"  => "http://packages.couchbase.com/releases/4.0.0-beta/couchbase-server-enterprise-4.0.0-beta-centos6.x86_64",
              "centos7"  => "http://packages.couchbase.com/releases/4.0.0-beta/couchbase-server-enterprise-4.0.0-beta-centos7.x86_64",
              "debian7"  => "http://packages.couchbase.com/releases/4.0.0-beta/couchbase-server-enterprise_4.0.0-beta-debian7_amd64",
              "debian8-unsupported"  => "http://packages.couchbase.com/releases/4.0.0-beta/couchbase-server-enterprise_4.0.0-beta-debian7_amd64",
              "opensuse11"   => "http://packages.couchbase.com/releases/4.0.0-beta/couchbase-server-enterprise-4.0.0-beta-suse11.3.x86_64",
              "opensuse12-unsupported" => "http://packages.couchbase.com/releases/4.0.0-beta/couchbase-server-enterprise-4.0.0-beta-suse11.3.x86_64",
              "ubuntu12" => "http://packages.couchbase.com/releases/4.0.0-beta/couchbase-server-enterprise_4.0.0-beta-ubuntu12.04_amd64",
              "ubuntu14" => "http://packages.couchbase.com/releases/4.0.0-beta/couchbase-server-enterprise_4.0.0-beta-ubuntu14.04_amd64",
             },
  "4.0.0-dp" => {
              "centos6"  => "http://packages.couchbase.com/releases/4.0.0-dp/couchbase-server-enterprise-4.0.0-dp-centos6.x86_64",
              "centos7"  => "http://packages.couchbase.com/releases/4.0.0-dp/couchbase-server-enterprise-4.0.0-dp-centos7.x86_64",
              "debian7"  => "http://packages.couchbase.com/releases/4.0.0-dp/couchbase-server-enterprise_4.0.0-dp-debian7_amd64",
              "debian8-unsupported"  => "http://packages.couchbase.com/releases/4.0.0-dp/couchbase-server-enterprise_4.0.0-dp-debian7_amd64",
              "opensuse11"   => "http://packages.couchbase.com/releases/4.0.0-dp/couchbase-server-enterprise-4.0.0-dp-suse11.3.x86_64",
              "opensuse12-unsupported" => "http://packages.couchbase.com/releases/4.0.0-dp/couchbase-server-enterprise-4.0.0-dp-suse11.3.x86_64",
              "ubuntu12" => "http://packages.couchbase.com/releases/4.0.0-dp/couchbase-server-enterprise_4.0.0-dp-ubuntu12.04_amd64",
              "ubuntu14" => "http://packages.couchbase.com/releases/4.0.0-dp/couchbase-server-enterprise_4.0.0-dp-ubuntu14.04_amd64",
             },
  "4.0.0-testing" => {
              "centos6"  => "http://latestbuilds.hq.couchbase.com/couchbase-server/sherlock/3570/couchbase-server-enterprise-4.0.0-3570-centos6.x86_64",
              "centos7"  => "http://latestbuilds.hq.couchbase.com/couchbase-server/sherlock/3570/couchbase-server-enterprise-4.0.0-3570-centos7.x86_64",
              "debian7"  => "http://latestbuilds.hq.couchbase.com/couchbase-server/sherlock/3570/couchbase-server-enterprise_4.0.0-3570-debian7_amd64",
              "debian8-unsupported"  => "http://latestbuilds.hq.couchbase.com/couchbase-server/sherlock/3570/couchbase-server-enterprise_4.0.0-3570-debian7_amd64",
              "opensuse11"   => "http://latestbuilds.hq.couchbase.com/couchbase-server/sherlock/3570/couchbase-server-enterprise-4.0.0-3570-suse11.x86_64",
              "opensuse12-unsupported"  => "http://latestbuilds.hq.couchbase.com/couchbase-server/sherlock/3570/couchbase-server-enterprise-4.0.0-3570-suse11.x86_64",
              "ubuntu12" => "http://latestbuilds.hq.couchbase.com/couchbase-server/sherlock/3570/couchbase-server-enterprise_4.0.0-3570-ubuntu12.04_amd64",
              "ubuntu14" => "http://latestbuilds.hq.couchbase.com/couchbase-server/sherlock/3570/couchbase-server-enterprise_4.0.0-3570-ubuntu14.04_amd64",
             },
}

default_number_of_nodes = 4
default_RAM_in_MB = 1024
default_number_of_cpus = 1

## Edit these to allow other machines in your network to access the VMs

# Set to true to activate non-host access
#  make sure no one else will be impacted by this, as VMs will have forced ip that could collide
#  (typically you should be close to alone on the LAN, with a few machines, ie at home)
# alternatively set use_dhcp to true to avoid this (at the cost of not knowing the IP in advance)
public_lan = false
use_dhcp = false

# Name of the host endpoint to serve as bridge to local network
#  (if not found vagrant will ask the user for each node)
default_bridge = "wlan0"

# Base for IP in public network. %d replaced by node number, eg "192.168.1.10%d" to get 101, 102, ...
#  (once again, be careful of potential ip collisions!)
public_ip_base = "192.168.1.10%d"


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

unless ENV['VAGRANT_VPN'].nil?
  vpn = "on"
else
  vpn = "off"
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

# Generate a hostname template
hostname = "#{version.gsub '.', ''}-#{operating_system}.vagrants"
if hostname =~ /^[0-9]/
  hostname.prepend("cb")
end
hostname.prepend("node%d-")

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
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "#{vpn}"]
  end
  config.vm.provider :libvirt do |libvirt|
    libvirt.memory = ram_in_MB
    libvirt.cpus = num_cpus
  end

  config.vm.synced_folder ENV['HOME'], "/vmhost_home/"

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
      if public_lan && use_dhcp
        node.vm.network :public_network, :bridge => default_bridge
        puts "Public LAN ip obtained via DHCP, find it by connecting to the node: vagrant ssh node#{num}"
      elsif public_lan
       node.vm.network :public_network, :bridge => default_bridge, :ip =>  public_ip_base % num
       puts "Public LAN ip : #{public_ip_base % num}"
      else
        node.vm.network :private_network, :ip => ip_address % num
        if Vagrant.has_plugin?("landrush")
          puts "Private network (host only) : http://#{hostname % num}:8091/"
        else
          puts "Private network (host only) : http://#{ip_address % num}:8091/"
        end
      end
      node.vm.hostname = hostname % num
      node.vm.provider "virtualbox" do |v|
        v.name = "Couchbase Server #{version} #{operating_system.gsub '/', '_'} Node #{num}"
        if(operating_system.include?("win")) # If the VM is running Windows it will start with a GUI
          v.gui = true
        end
      end
      if Vagrant.has_plugin?("landrush")
        node.landrush.enabled = true
        node.landrush.tld = "vagrants"
      end
      # Postfix a random value to hostname to uniquify it.
      node.vm.provider "libvirt" do |v|
        v.random_hostname = true
      end
    end
  end

  if ARGV[0] == "up" && !ARGV[1]
    if public_lan && use_dhcp
      puts "\e[32m=== Upping #{num_nodes} node(s) on public LAN via DHCP ==="
    elsif public_lan
      puts "\e[32m=== Upping #{num_nodes} node(s) on public LAN IPs #{public_ip_base.sub('%d','')}{1..#{num_nodes}} ==="
    else
      puts "\e[32m=== Upping #{num_nodes} node(s) on IPs #{ip_address.sub('%d','')}{1..#{num_nodes}} ==="
    end
  end

end
rescue
end
