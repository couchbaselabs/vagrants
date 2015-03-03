file {'/tmp/test1':
  ensure  => present,
  content => "Hello World!",
}

package { "telnet" :
  ensure => present
} 

package { 'httpd' : ensure => installed }
service { 'httpd' : ensure => running   }

file { '.bashrc' :
  source => '/vagrant/.bashrc',
  path => '/home/vagrant/.bashrc'
}

file { '/var/www':
  ensure => 'directory'
}

file { '/var/www/html':
  ensure => 'directory',
  require => File['/var/www']
}

file { 'wwwroot' :
  source => '/vagrant/wwwroot',
  path => '/var/www/html/wwwroot',
  recurse => true,
  require => File['/var/www/html']
}

exec { "turn-off-firewall" :
  command => "/usr/bin/sudo service iptables stop",
  logoutput => on_failure
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
  require => Package['php-pear']
}

exec { "fix-php-ini" :
  command => "/usr/bin/sudo chmod 666 /etc/php.ini; /usr/bin/sudo echo extension=/usr/lib64/php/modules/couchbase.so >> /etc/php.ini",
  logoutput => on_failure,
  require => Exec['install-cb-php-sdk']
}

exec { "restart-apache" :
  command => "/usr/bin/sudo service httpd restart",
  logoutput => on_failure,
  require => Exec['fix-php-ini']
}

# Print all the versions of everything before exiting
# Log them all to a file

exec { "done-hello-world" :
  command => "/bin/echo 'Hello World' at `date`",
  require => Exec['install-cb-php-sdk'],
  logoutput => true
}

# The real FINAL step

exec { "make-list-of-all-files" :
  command => "/usr/bin/sudo find / -nowarn -type f > /home/vagrant/all-files-list 2>&1; echo",
  require => Exec['done-hello-world'],
  logoutput => true
}
