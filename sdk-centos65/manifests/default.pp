file {'/tmp/test1':
  ensure  => present,
  content => "Hello World!",
}

# TODO figure out how to do this, it wants urls or fully qualified paths
file { '.bashrc' :
  source => '/vagrant/.bashrc',
  path => '/home/vagrant/.bashrc'
}

exec { "download-libcb-repo":
  command => "/usr/bin/wget -O/etc/yum.repos.d/couchbase.repo http://packages.couchbase.com/rpm/couchbase-centos62-x86_64.repo",
  logoutput => on_failure
}

#exec { "update-yum" :
#  command => '/usr/bin/yum check-update',
#  require => Exec['download-libcb-repo'],
#  logoutput => on_failure
#}

package { "libcouchbase2-bin" :
  ensure => present, 
  #require => Exec['update-yum'],
  require => Exec['download-libcb-repo']
}

package { "libcouchbase-devel" :
  ensure => present,
  require => Package["libcouchbase2-bin"]
} 

package { "libcouchbase2-libevent" :
  ensure => present,
  require => Package["libcouchbase-devel"]
} 

# End of libcouchbase stuff

# Install python couchbase

exec { "bootstrap-pip" :
  command => "/usr/bin/wget --no-check-certificate -O/tmp/get-pip.py https://bootstrap.pypa.io/get-pip.py",
  logoutput => on_failure
}

exec { "python-get-pip" :
  command => "/usr/bin/python /tmp/get-pip.py",
  require => Exec['bootstrap-pip'],
  logoutput => on_failure
}

package { "python-devel" :
  ensure => present,
  require => Exec['python-get-pip']
}

# end of install python couchbase

# PHP stuff 

package { 
	"php": 
	ensure => present,
        require => Package["libcouchbase2-libevent"]
}

package { 
	"php-devel": 
	ensure => present,
	require => Package["php"]
}

package { 
	"php-pear": 
	ensure => present,
  	require => Package["php-devel"]
}


exec { "install-cb-php-sdk" :
  command => "/usr/bin/sudo pecl install couchbase",
  require => Package['php-pear'],
  logoutput => true
}


# Print all the versions of everything before exiting
# Log them all to a file

exec { "done-display-versions" :
  command => "/bin/echo 'Hello World' at `date`",
  require => Exec['install-cb-php-sdk'],
  logoutput => true
}


