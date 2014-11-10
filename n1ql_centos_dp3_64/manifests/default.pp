# ===
# Install Couchbase N1QL DP3 
# ===

$version = "DP3"

# create a DP3 directory      
file { "/home/vagrant/n1ql-dp3":
    ensure => "directory",
}

# Download the Sources
exec { "couchbase-n1ql-source":
    command => "/usr/bin/wget https://s3.amazonaws.com/query-dp3/couchbase-query_dev_preview3_x86_64_linux.tar.gz",
    cwd => "/home/vagrant/n1ql-dp3/",
    creates => "/home/vagrant/n1ql-dp3/couchbase-query_dev_preview3_x86_64_linux.tar.gz",
    require => File['/home/vagrant/n1ql-dp3'],
}

# Untar the N1QL Pkg
exec { "untar n1ql":
   command => "/bin/tar -zxvf couchbase-query_dev_preview3_x86_64_linux.tar.gz",
   cwd => "/home/vagrant/n1ql-dp3/",
   onlyif => "/usr/bin/test -f /home/vagrant/n1ql-dp3/couchbase-query_dev_preview3_x86_64_linux.tar.gz",
   require => Exec['couchbase-n1ql-source'],
}

# Start N1QL Tutorial script
exec { "start tutorial":
  command => "/usr/bin/nohup /home/vagrant/n1ql-dp3/start_tutorial.sh > /tmp/n1ql-dp3-tutorial_out 2> /tmp/n1ql-dp3-tutorial_err &",
  require => Exec['untar n1ql'],
}

# Ensure firewall is off (some CentOS images have firewall on by default).
service { "iptables":
        ensure => "stopped",
        enable => false,
      }
