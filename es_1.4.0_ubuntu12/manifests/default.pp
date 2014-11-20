# ===
# Install Elastic Search 1.4.0 + CB ES Plugin 2.0 
# ===


exec { "wget es deb": 
   command => "/usr/bin/wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.4.0.deb --output-document=/vagrant/elasticsearch-1.4.0.deb", 
   path => "/usr/bin",
   creates => "/vagrant/elasticsearch-1.4.0.deb",
} 

# Update the System
  exec { "aptitude update":
             command => "aptitude update && touch /tmp/updated",
             path => "/usr/bin",
             creates => "/tmp/updated",
             require => Exec['wget es deb'], 
  }

# Install Java JDK

package { "java7-jdk" :
      ensure => installed,
      require => Exec['aptitude update'],
}

# Install the ES package
  exec { "dpkg es.deb":
		command => "sudo /usr/bin/dpkg -i /vagrant/elasticsearch-1.4.0.deb",
		path => "/usr/bin",
		creates => "/etc/init.d/elasticsearch",
		require => Package['java7-jdk'],	
	}

# Start ES
  exec { "elasticsearch start":
                command => "/etc/init.d/elasticsearch start",
		path => "/etc/init.d",
                require => Exec['dpkg es.deb']
        }

# Install CB ES Plugin
  exec { "install CB ES plugin 2.0":
                command => "/usr/bin/sudo /usr/share/elasticsearch/bin/plugin -install transport-couchbase -url http://packages.couchbase.com.s3.amazonaws.com/releases/elastic-search-adapter/2.0.0/elasticsearch-transport-couchbase-2.0.0.zip",
                path => "/usr/share/elasticsearch",
                require => Exec['elasticsearch start']
        }

