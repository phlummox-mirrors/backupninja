What should I do when rdiff-backup fails?
=========================================

If rdiff-backup fails, the meta data file may get corrupt. When this
happens, rdiff-backup will complain loudly every time it is run and
possibly fail to backup some or all the files.

To force rdiff-backup to rebuild the meta data, set this option in
the `.rdiff` backup action file:

        options = --force

After a rdiff-backup run has been successful you should remove
this option.

How to restrict privileges on the backup server?
================================================

backupninja uses a "push" mechanism, where backups are sent from one
or several hosts to a centralized backup server.

Mount your backup partition with limited execution rights
---------------------------------------------------------

Edit `/etc/fstab` to mount your partition with limited rights. For example:

        /home           ext3    defaults,nosuid,noexec,nodev      0       2

Create a user for each client
-----------------------------

On the backup server, it is important to create a separate user for
each client.

Use a restricted shell and jail users
-------------------------------------

Furthermore, you may use a restricted shell like
[rssh](http://www.pizzashack.org/rssh/index.shtml) or
[scponly](http://sublimation.org/scponly/wiki/index.php/Main_Page),
which also offer the ability to jail connections.

On the backup server:

        $ apt-get install scponly
        $ adduser --disabled-password --home /home/backup/ninja-host1 --shell /usr/bin/scponly ninja-host1

You may now use `ninja-host1` user to connect to the
`/home/backup/ninja-host1` jail.
