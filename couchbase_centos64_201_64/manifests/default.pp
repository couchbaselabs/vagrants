# ===
# Install and Run Couchbase Server
# ===

$version = "2.0.1"
$stem = "couchbase-server-enterprise_x86_64_$version"
$suffix = $operatingsystem ? {
    Ubuntu => ".deb",
    CentOS => ".rpm",
}
$filename = "$stem$suffix"

# Download the Sources
exec { "couchbase-server-source":
    command => "/usr/bin/wget http://packages.couchbase.com/releases/$version/$filename",
    cwd => "/vagrant/",
    creates => "/vagrant/$filename",
    before => Package['couchbase-server']
}

# Install libssl dependency
package { "libssl0.9.8":
    name => $operatingsystem ? {
        Ubuntu => "libssl0.98",
        CentOS => "openssl098e",
    },
    ensure => present
}

# Install Couchbase Server
package { "couchbase-server":
    provider => $operatingsystem ? {
        Ubuntu => dkpg,
        CentOS => rpm,
    },
    ensure => installed,
    source => "/vagrant/$filename",
    require => Package["libssl0.9.8"]
}

# Ensure firewall rules are flushed (brute force, some CentOS images have firewall
# on by default).
service { "iptables":
    enable => false
}

# Ensure the service is running
service { "couchbase-server":
	ensure => "running",
	require => Package["couchbase-server"]
}
