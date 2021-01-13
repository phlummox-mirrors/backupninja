Installation
============

On Debian, Ubuntu and derivatives
---------------------------------

Run `apt-get install backupninja`.

By hand
-------

Requirements:

        bash gawk

Recommended:

        borgbackup cryptsetup duplicity flashrom gzip hwinfo rdiff-backup restic rsync sfdisk

To install backupninja, simply do the following:

        $ ./autogen.sh
        $ ./configure
        $ make
        $ make install

You may wish to change the install locations, or other options. To find
the available possibilities, run `./configure --help`.
