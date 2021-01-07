#!/bin/bash

# A minimal testsuite for backupninja

# This is meant to be run inside a development environment,
# so give the user a chance to bail
if [ ! -d "/vagrant" ]; then
    read -p "This doesn't look like a test environment (Vagrant). Continue anyway? " -n 1 -r
	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# Are we root?
if [[ "$USER" != "root" ]]; then
    echo "Please run the test suite as root."
    exit 1
fi

# Is backupninja in $PATH ?
if [ ! "$(which backupninja)" ]; then
    echo "Couldn't find 'backupninja', is it installed?"
    exit 1
fi

# Install basic test dependencies
apt-get -qq install bats mailutils faketime crudini

# Create a temporary base directory
TMPDIR=$(mktemp -t -d bntest.XXXXXX)
export TMPDIR

# Mount temporary directories in tmpfs
# this should speed up the tests a little bit
mount -t tmpfs tmpfs "$TMPDIR"
mount -t tmpfs tmpfs /var/backups

# Run actual tests
if [ -z "$1" ]; then
    for t in "$(dirname "$0")"/*.bats; do
        echo "# $(basename -s .bats "$t")"
        bats "$t"
        echo
    done
else
    echo "# $1"
    bats "$(dirname "$0")/${1}.bats"
fi


# Clean up
umount "$TMPDIR"
umount /var/backups
rmdir "$TMPDIR"

exit 0
