# ===
# Install and Run Couchbase Server
# ===

$suffix = $operatingsystem ? {
    Ubuntu => ".deb",
    CentOS => ".rpm",
}

$fullUrl = "$url$suffix"
$splitter = split($fullUrl, '/')
$filename = $splitter[-1]

# Download the Sources
exec { "couchbase-server-source":
    command => "/usr/bin/wget $fullUrl",
    cwd => "/vagrant/",
    creates => "/vagrant/$filename",
    before => Package['couchbase-server']
}

if $operatingsystem == 'Ubuntu'{
  # Update the System
  exec { "apt-get update":
	     path => "/usr/bin"
  }
}
else{
  # Ensure firewall is off (some CentOS images have firewall on by default).
    service { "iptables":
      ensure => "stopped",
      enable => false
    }
}

# Install libssl dependency
package { "libssl0.9.8":
    name => $operatingsystem ? {
        Ubuntu => "libssl0.9.8",
        CentOS => "openssl098e",
    },
    ensure => present,
    before => Package["couchbase-server"]
}

# Install Couchbase Server
package { "couchbase-server":
    provider => $operatingsystem ? {
        Ubuntu => dpkg,
        CentOS => rpm,
    },
    ensure => installed,
    source => "/vagrant/$filename",
}

# Ensure the service is running
service { "couchbase-server":
	ensure => "running",
	require => Package["couchbase-server"]
}
