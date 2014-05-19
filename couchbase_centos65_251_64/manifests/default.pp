# ===
# Install and Run Couchbase Server
# ===

$version = "2.5.1"
$stem = "couchbase-server-enterprise_${version}_x86_64"
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

# Install Couchbase Server
package { "couchbase-server":
    provider => $operatingsystem ? {
        Ubuntu => dkpg,
        CentOS => rpm,
    },
    ensure => installed,
    source => "/vagrant/$filename",
}

# Ensure firewall is off (some CentOS images have firewall on by default).
service { "iptables":
    	ensure => "stopped"
	enable => false,
}

# Ensure the service is running
service { "couchbase-server":
	ensure => "running",
	require => Package["couchbase-server"]
}
