Upstream
========

* update version in `configure.in`

* update first line of `ChangeLog`

* commit:

        git commit configure.in ChangeLog \
            -m "Releasing backupninja $VERSION"

* create the tarball:

        git tag -s "backupninja-$VERSION" \
            -m "Releasing backupninja $VERSION"
        ./autogen.sh
        ./configure
        make dist

* compare the content of the generated tarball with the content of the
  previous one

* `mv backupninja-$VERSION.tar.gz ../tarballs/`

* cleanup: `make distclean`

* sign the release:

        cd ../tarballs
        gpg --armor --detach-sign backupninja-$VERSION.tar.gz

* upload the generated tarball and detached signature to
  https://0xacab.org/riseuplabs/backupninja/

* push master branch and tags:

        git push origin master --follow-tags

* announce on the backupninja mailing-list

Debian
======

        ln -s backupninja-$VERSION.tar.gz backupninja_$VERSION.orig.tar.gz
        cd ../git
        git checkout debian
        gbp import-orig --upstream-vcs-tag="backupninja-$VERSION" \
            ../tarballs/backupninja-$VERSION.tar.gz
        gbp dch --auto
        dch -e
        git commit debian/changelog -m "Releasing backupninja ($DEBIAN_VERSION) to Debian unstable"
        git tag -s -m "Releasing backupninja ($DEBIAN_VERSION) to Debian unstable" backupninja_debian/$DEBIAN_VERSION
        gbp buildpackage

* push the `debian` branch
* publish the source package somewhere
* ask someone listed in the `Uploaders` control field to review and upload
* push the tag, once uploaded to Debian
