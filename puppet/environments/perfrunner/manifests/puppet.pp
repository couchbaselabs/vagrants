# Perfrunner Puppet file
# Note most commands need to be executed in order of appearance
# Update the apt-database, install the required apt-packages then pip packages
# And clone the perfrunner repo into the vagrant home dir

exec { "install libcouchbase repo":
	command => "/usr/bin/wget http://packages.couchbase.com/releases/couchbase-release/couchbase-release-1.0-2-amd64.deb && /usr/bin/dpkg -i couchbase-release-1.0-2-amd64.deb",
	alias	=> "libcouchbase_repo"
}

exec { "/usr/bin/apt-get update":
    alias   => "apt-get-update",
    require => Exec['libcouchbase_repo']
}

$perfrunner_deps = [ "git", "gcc", "python-dev", "python-pip", "libffi-dev", "libyaml-dev", "libssl-dev", "libcouchbase-dev", "libcouchbase2-bin", "build-essential" ]
package { $perfrunner_deps:
    ensure => "installed",
    require => Exec['apt-get-update'],
}

$perfrunner_pips = [ "couchbase", "virtualenv", "cryptography",  "paramiko" ]
package { $perfrunner_pips:
    ensure => present,
    provider => "pip",
    require => Package[$perfrunner_deps],
}

exec {"/usr/bin/git clone https://github.com/couchbase/perfrunner.git /home/vagrant/perfrunner":
     alias => "clone_perfrunner",
     creates => "/home/vagrant/perfrunner",
     require => Package[$perfrunner_deps],
     user => "vagrant"
}
