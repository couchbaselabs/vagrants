# ===
# Install and Run Couchbase Server
# ===

$suffix = $operatingsystem ? {
    Ubuntu => ".deb",
    CentOS => ".rpm",
}

# Doublecheck this, as url may already include this if passed by ENV
if $suffix in $url {
  $fullUrl = "$url"
} else {
  $fullUrl = "$url$suffix"
}

$splitter = split($fullUrl, '/')
$filename = $splitter[-1]

# Download the Sources
exec { "sync_gateway-source":
    command => "/usr/bin/wget $fullUrl",
    cwd => "/vagrant/",
    creates => "/vagrant/$filename",
    before => Package['sync_gateway'],
    timeout => 1200
}

if $operatingsystem == 'Ubuntu' or $operatingsystem == 'Debian'{
  # Update the System
  exec { "apt-get update":
	     path => "/usr/bin"
  }
}
elsif $operatingsystem == 'CentOS'{
  case $::operatingsystemmajrelease {
    '5', '6': {
      # Ensure firewall is off (some CentOS images have firewall on by default).
      service { "iptables":
        ensure => "stopped",
        enable => false
      }
    }
    '7': {
      # This becomes 'firewalld' in RHEL7'
      service { "firewalld":
        ensure => "stopped",
        enable => false
      }
    }
  }

  # Install pkgconfig (not all CentOS base boxes have it).
  package { "pkgconfig":
    ensure => present,
    before => Package["sync_gateway"]
  }
}

notice("Installing libssl for ${operatingsystem} ${operatingsystemrelease}")
# Install libssl dependency
package { "libssl":
    name => $operatingsystem ? {
        Ubuntu => $::operatingsystemrelease ? {
    		'10.04' => "libssl0.9.8",
    		'12.04' => "libssl1.0.0",
    		'14.04' => "libssl1.0.0",
     		'16.04' => "libssl1.0.0"},
        CentOS => "openssl098e",
        Debian => "libssl1.0.0",
        OpenSuSE => "openssl",
    },
    ensure => present,
    before => Package["sync_gateway"]
}

# Install Sync Gateway
package { "sync_gateway":
    provider => $operatingsystem ? {
        Ubuntu => dpkg,
        CentOS => rpm,
        Debian => dpkg,
        OpenSuSE => rpm,
    },
    ensure => installed,
    source => "/vagrant/$filename",

}

# Copy config if one supplied
exec { "sync_gateway-config":
    command => "/bin/cp /vagrant/sync_gateway.json /home/sync_gateway/sync_gateway.json",
    returns => [0,1],
    notify => Service["sync_gateway"],
    require => Package["sync_gateway"]
}

# Ensure the service is running
service { "sync_gateway":
  provider => $operatingsystem ? {
      Ubuntu => $::operatingsystemrelease ? {
        '12.04' => "upstart",
        '14.04' => "upstart",
        '16.04' => "systemd"},
      CentOS => $::operatingsystemmajrelease ? {
        '5' => "service",
        '6' => "upstart",
        '7' => "systemd"}
  },
	ensure => "running"
}
