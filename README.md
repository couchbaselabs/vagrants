# Vagrant files for Couchbase Server VMS

## Starting a Couchbase cluster

If vagrant and virtualbox are installed, it is very easy to get started with a 4 node cluster.

See this blog post for more info: http://nitschinger.at/A-Couchbase-Cluster-in-Minutes-with-Vagrant-and-Puppet

Just change into the directories and call "vagrant up". Everything else will be done for you, but you need
internet access.

## Building Couchbase

The subdirectory `cbdev_ubuntu_1204` contains a Vagrant configuration for
building Couchbase from source; for Ubuntu 12.04. With this you should be able to build the master branch with the following:

*outside on host*:

    cd cbdev_ubuntu_1204
    vagrant up; vagrant ssh

*inside vagrant VM*:

    mkdir couchbase; cd couchbase
    repo init -u git://github.com/couchbase/manifest -m branch-master.xml
    repo sync
    make

To build a specific release, change the `branch-master.xml` file to be one of the release files from the [manifests repository][1]. Look for filenames of the form `rel-X.x.x.xml`. 
e.g. to build 2.5.1 from source you would change the above `repo init` command to be:
    
    repo init -u git://github.com/couchbase/manifest -m rel-2.5.1.xml

[1]: https://github.com/couchbase/manifest
    
See https://github.com/couchbase/tlm/ more information on building Couchbase from source.
