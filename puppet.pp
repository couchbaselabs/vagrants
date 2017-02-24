# ===
# Install and Run Couchbase Server
# ===

$suffix = $operatingsystem ? {
    Ubuntu => ".deb",
    CentOS => ".rpm",
    Debian => ".deb",
    OpenSuSE => ".rpm",
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
exec { "couchbase-server-source":
    command => "/usr/bin/wget $fullUrl",
    cwd => "/vagrant/",
    creates => "/vagrant/$filename",
    before => Package['couchbase-server'],
    timeout => 1200
}

if $operatingsystem == 'Ubuntu' or $operatingsystem == 'Debian'{
  # Update the System
  exec { "apt-get update":
	     path => "/usr/bin"
  }
}
elsif $operatingsystem == 'OpenSuSE'{
  package {"patterns-openSUSE-minimal_base-conflicts":
  ensure => absent,
  before => Package["python"]}

  # Install python
  package { "python":
    ensure => present,
    before => Package["couchbase-server"]
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
    before => Package["couchbase-server"]
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
    before => Package["couchbase-server"]
}

# Install Couchbase Server
package { "couchbase-server":
    provider => $operatingsystem ? {
        Ubuntu => dpkg,
        CentOS => rpm,
        Debian => dpkg,
        OpenSuSE => rpm,
    },
    ensure => installed,
    source => "/vagrant/$filename",
}

# Ensure the service is running
service { "couchbase-server":
	ensure => "running",
	require => Package["couchbase-server"]
}
