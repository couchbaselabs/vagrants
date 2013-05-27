exec { "couchbase-server-source":
    command => "/usr/bin/wget http://packages.couchbase.com/releases/2.0.1/couchbase-server-enterprise_x86_64_2.0.1.deb",
    cwd => "/home/vagrant/",
    creates => "/home/vagrant/couchbase-server-enterprise_x86_64_2.0.1.deb",
    before => Package['couchbase-server'],
    timeout => 0
}

exec { "install-deps":
    command => "/usr/bin/apt-get install libssl0.9.8",
    before => Package['couchbase-server'],
    timeout => 0
}

package { "couchbase-server":
    provider => dpkg,
    ensure => installed,
    source => "/home/vagrant/couchbase-server-enterprise_x86_64_2.0.1.deb"
}
