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
    cd ns_server; ./cluster_run --nodes=1

To build a specific release, change the `branch-master.xml` file to be one of the release files from the [manifests repository][1]. Look for filenames of the form `rel-X.x.x.xml`. 
e.g. to build 2.5.1 from source you would change the above `repo init` command to be:
    
    repo init -u git://github.com/couchbase/manifest -m rel-2.5.1.xml

[1]: https://github.com/couchbase/manifest
    
See https://github.com/couchbase/tlm/ more information on building Couchbase from source.


## Vagrant and KVM

Vagrant by default uses Virtualbox as the VM hypervisor. This is a
good general-purpose solution, but is not as performant compared to
KVM, particulary for SMP, network-heavy workloads.

Vagrant can instead be configured to use KVM as it backend, using the
vagrant-libvirt plugin.

*Note:* KVM and Virtualbox VMs **cannot** both run at the same time -
if you try to start a KVM VM when a Virtualbox VM is running, the KVM
VM will not start (and vice versa).

This requires:

1.  A one-off configuration of the KVM plugin into Vagrant.
2.  For each VM:
    a.  Ensuring the base-box is available for libvirt
    b.  Any backend-specific settings (CPUs, memory) are also set for libvirt.

### Installing vagrant-libvirt

Follow the installation instructions at the plugin's [homepage](https://github.com/pradels/vagrant-libvirt#installation)


### Updating a VM for use in KVM

Most of the Vagrant settings for a VM will work unchanged between
Virtualbox and KVM, however there are two exceptions. Firstly a base
box supporting libvirt is needed - the easiest method is to convert an
existing (non-libvirt) basebox to libvirt format.

#### Convert a base-box to libvirt format.

The [Vagrant-Mutate](https://github.com/sciurus/vagrant-mutate) plugin
is the simplest method, as it can directly convert an existing
base-box to libvirt.

1.  Install vagrant-mutate with:

        $ vagrant plugin install vagrant-mutate

2.  Determine the box which needs converting. This is a one-off
    process for each box you wish to use. The easiest way to do this
    is to attempt to start the (non-libvirt) VM you wish to use, and
    note the name of the box in the Vagrant error message - for example:

        $ vagrant up --provider=libvirt node1

        ...
        The box you're attempting to add doesn't support the provider
        you requested. Please find an alternate box or use an alternate
        provider. Double-check your requested provider to verify you didn't
        simply misspell it.

        Name: centos-6.5-64
        Address: https://vagrantcloud.com/puppetlabs/centos-6.5-64-puppet
        Requested provider: [:libvirt]

    Make a note of the box name (`centos-6.5-64` here).

3.  Use `vagrant mutate` to create a libvirt version of the box.

        $ vagrant mutate centos-6.5-64 libvirt

#### Update any provider-specific settings

If you have set hardware-level settings (memory, CPU count) in the
Vagrantfile for virtualbox then these need an equivilent setting for
libvirt. For example, the virtualbox settings:

    config.vm.provider "virtualbox" do |vb|
      vb.memory = 2048
      vb.cpus = 2
    end

Will require an equivilent stanza for libvirt:

    config.vm.provider :libvirt do |libvirt|
      libvirt.memory = 2048
      libvirt.cpus = 2
    end

See the [Domain Specific Options](https://github.com/pradels/vagrant-libvirt#domain-specific-options)
in the vagrant-libvirt docuementation for a complete list of possible
options.

##### Running with KVM

You should now be able to bring up the VM using libvirt (KVM):

    $ vagrant up --provider=libvirt node1


Note that most (all?) normal vagrant commands should work as before
(vagrant ssh, vagrant halt, etc), the only important different is to
specify `--provider=libvirt` to the `vagrant up`
command. Alternatively you can make this the default by setting

    $ export VAGRANT_DEFAULT_PROVIDER=libvirt
