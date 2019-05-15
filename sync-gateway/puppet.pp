# ===
# Install and Run Sync Gateway
# ===

$suffix = $operatingsystem ? {
    'Ubuntu' => ".deb",
    'CentOS' => ".rpm",
    'Debian' => ".deb",
    'OpenSuSE' => ".rpm",
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

if $operatingsystem == 'CentOS'{
  case $::operatingsystemmajrelease {
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

# Install Sync Gateway
package { "sync_gateway":
    provider => $operatingsystem ? {
        'Ubuntu' => dpkg,
        'CentOS' => rpm,
        'Debian' => dpkg,
        'OpenSuSE' => rpm,
    },
    ensure => installed,
    source => "/vagrant/$filename",
}

# Ensure the service is running
service { "sync_gateway":
    ensure => "running",
    require => Package["sync_gateway"]
}
