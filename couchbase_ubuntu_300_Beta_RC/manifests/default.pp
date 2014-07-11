# ===
# Install and Run Couchbase Server
# ===

$version = "3.0.0-918-rel"
$stem = "couchbase-server-enterprise_ubuntu_1204_x86_64_${version}"
$suffix = $operatingsystem ? {
    Ubuntu => ".deb",
    CentOS => ".rpm",
}
$filename = "$stem$suffix"

# Download the Sources
exec { "couchbase-server-source":
    command => "/usr/bin/wget http://packages.northscale.com/latestbuilds/3.0.0/$filename",
    cwd => "/home/vagrant/",
    creates => "/home/vagrant/${filename}",
    before => Package['couchbase-server']
}

# Update the System
exec { "apt-get update":
	path => "/usr/bin"
}

# Install Couchbase Server
package { "couchbase-server":
    provider => dpkg,
    ensure => installed,
    source => "/home/vagrant/${filename}"
}

# Ensure the service is running
service { "couchbase-server":
	ensure => "running",
	require => Package["couchbase-server"]
}
