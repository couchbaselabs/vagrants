# ===
# Install Couchbase Sync Gateway
# ===

$version = "1.0.0"
$filename = "couchbase-sync-gateway-enterprise_${version}_x86_64.deb"

# Download the Sources
exec { "couchbase-server-source":
    command => "/usr/bin/wget http://packages.couchbase.com/releases/couchbase-sync-gateway/${version}/${filename}",
    cwd => "/home/vagrant/",
    creates => "/home/vagrant/${filename}",
    before => Package['couchbase-sync-gateway']
}

# Update the System
exec { "apt-get update":
	path => "/usr/bin"
}

# Install Couchbase Server
package { "couchbase-sync-gateway":
    provider => dpkg,
    ensure => installed,
    source => "/home/vagrant/${filename}",
}
