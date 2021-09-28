When developping fixes or new features for backupninja, it is highly recommended
to run the test suite to help spot potential problems.

The test suite is based on Vagrant, and is configured to rely on the VirtualBox
provider. The required package may be installed using the following command:

    apt install vagrant virtualbox

On Debian 10 (buster) these packages aren't available in the default upstream
repositories, so you will need to use an alternative such as the one provided
by an individual Debian developper here:

    https://people.debian.org/~lucas/virtualbox-buster/

Once the requirements are in place, the test suite may be run in this manner:

    git clone git@0xacab.org:liberate/backupninja.git
    cd backupninja
    vagrant up
    vagrant ssh -c "sudo /vagrant/test/test.sh"

It's possible to only test a specific handler with:

    vagrant ssh -c "sudo /vagrant/test/test.sh rdiff"

To synchronise changes in the source code and rebuild backupninja:

    vagrant rsync local && vagrant ssh -c "build-backupninja.sh"

Please report any problems with the test suite on the issue tracker at:

    https://0xacab.org/liberate/backupninja/-/issues
