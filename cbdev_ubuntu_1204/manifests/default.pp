package { 'python-software-properties':
        ensure  =>  latest,
}
exec { "/usr/bin/apt-add-repository ppa:yjwong/cmake && /usr/bin/apt-get update":
    alias   => "ppa_cmake",
    require => Package["python-software-properties"],
    creates => "/etc/apt/sources.list.d/yjwong-cmake.list"
}

# Needed for building couchbase
$build_deps = [ "build-essential", "git", "cmake", "libevent-dev",
                "libcurl4-openssl-dev", "libicu-dev", "libsnappy-dev",
                "libv8-dev", "erlang", "erlang-src" ]
package { $build_deps:
        ensure => "installed",
        require => Exec["ppa_cmake"]
}

exec {"/usr/bin/curl https://storage.googleapis.com/git-repo-downloads/repo > /usr/local/bin/repo && chmod a+x /usr/local/bin/repo":
     alias => "install_repo",
     creates => "/usr/local/bin/repo"
}