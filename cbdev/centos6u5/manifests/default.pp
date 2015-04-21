# Repo - manages all our git repositories
exec {"/usr/bin/curl https://storage.googleapis.com/git-repo-downloads/repo > /usr/local/bin/repo &&
       chmod a+x /usr/local/bin/repo":
    alias => "install_repo",
    creates => "/usr/local/bin/repo"
}

# devtools-2 has updated versions of a number of development packages we need
exec { "/usr/bin/curl http://people.centos.org/tru/devtools-2/devtools-2.repo > /etc/yum.repos.d/devtools-2.repo":
    alias   => "devtools-2-repo",
    creates => "/etc/yum.repos.d/devtools-2.repo"
}

$devtools = ["devtoolset-2-binutils", "devtoolset-2-gcc", "devtoolset-2-gcc-c++",
             "devtoolset-2-git"]
package { $devtools:
    ensure  => installed,
    require => Exec["devtools-2-repo"]
}

# epel needed for cmake
package { "epel-release-6-8":
    ensure => installed,
    source => "http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm"
}

package { [ "openssl-devel", "redhat-lsb-core"]:
    ensure => installed
}

package { ["cmake", "golang"]:
    require => Package["epel-release-6-8"]
}

# devtoolset-2 installs things under /opt/r; add this to the path.
file { '/etc/profile.d/append-devtoolset-path.sh':
    mode    => 644,
    content => 'PATH=$PATH:/opt/rh/devtoolset-2/root/usr/bin'
}
