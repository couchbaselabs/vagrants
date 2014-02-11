# ===
# Install and Run Couchbase Server
# ===

$version = "2.5.0"
$filename = "couchbase-server-enterprise_${version}_x86_64.deb"

# Download the Sources
exec { "couchbase-server-source":
    command => "/usr/bin/wget http://packages.couchbase.com/releases/${version}/${filename}",
    cwd => "/home/vagrant/",
    creates => "/home/vagrant/${filename}",
    before => Package['couchbase-server']
}

# Update the System
exec { "apt-get update":
	path => "/usr/bin"
}

# Install libssl dependency
package { "libssl0.9.8":
	ensure => present,
	require => Exec["apt-get update"]
}

# Install Couchbase Server
package { "couchbase-server":
    provider => dpkg,
    ensure => installed,
    source => "/home/vagrant/${filename}",
    require => Package["libssl0.9.8"]
}

# Ensure the service is running
service { "couchbase-server":
	ensure => "running",
	require => Package["couchbase-server"]
}
