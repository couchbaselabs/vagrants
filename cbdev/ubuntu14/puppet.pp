exec { "/usr/bin/apt-get update":
    alias   => "apt-get-update",
}

# Needed for building couchbase
$couchbase_deps = [ "git", "cmake", "libevent-dev", "libcurl4-openssl-dev", "gccgo-go",
                "libicu-dev", "libsnappy-dev", "libv8-dev", "erlang",
                "erlang-src", "build-essential", "libgoogle-perftools-dev",
	 	"devscripts", "debhelper", "dh-virtualenv" ]
package { $couchbase_deps:
        ensure => "installed"
}

# Needed for pre-cmake (<3.0.0) builds:
$old_build_deps = [ "automake", "libtool", "cloog-ppl" ]
package { $old_build_deps:
        ensure => "installed"
}

# Some of the build tools expect a writeable /opt/couchbase directory
file { '/opt/couchbase':
     ensure => 'directory',
     owner  => 'vagrant',
     group  => 'vagrant',
     mode   => '0750',
}
 file { '/home/vagrant/.gitconfig':
	ensure => 'present',
	source => 'file:///vmhost_home/.gitconfig'
}

exec {"/usr/bin/wget -O- https://storage.googleapis.com/git-repo-downloads/repo > /usr/local/bin/repo && chmod a+x /usr/local/bin/repo":
     alias => "install_repo",
     creates => "/usr/local/bin/repo"
}
