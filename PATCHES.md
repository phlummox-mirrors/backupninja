
# Description of patches and fixes made to this repo

- This as-yet-unmerged fix from Andrew Bezella (merge request [here][luks-merge]).
  fixing a bug whereby LUKS headers can only successfully be backed up *once*
  (bug described [here][luks-bug]).

  See <https://github.com/phlummox-patches/backupninja/pull/1>

- Fix these bugs (<https://0xacab.org/liberate/backupninja/-/issues/11332>,
  <https://0xacab.org/liberate/backupninja/-/issues/11336>), whereby the duplicity
  "helper" (wizard) won't work at all.

  See <https://github.com/phlummox-patches/backupninja/pull/2>

- Fix this bug (<https://0xacab.org/liberate/backupninja/-/issues/11328>),
  which results in errors when the restic handler run using `--debug`

  (Commit 485b72e9916cb1abc44935782d5a4cc5f156a41a.)

- Add the ability to pass through arbitrary command-line options to the "restic backup"
  command (in the same way one can do for duplicity, see [here][dup-example-l9] and [here][dup-conf-l8]).

  (Pull request <https://github.com/phlummox-patches/backupninja/pull/3>).

  This patch adds that feature.

[dup-example-l9]: https://github.com/phlummox-patches/backupninja/blob/backupninja-1.2.1/examples/example.dup#L9
[dup-conf-l8]: https://github.com/phlummox-patches/backupninja/blob/backupninja-1.2.1/handlers/dup.in#L8


[luks-merge]: https://0xacab.org/liberate/backupninja/-/merge_requests/58
[luks-bug]: https://0xacab.org/liberate/backupninja/-/issues/11333

# Simplified `debian-*` branches

No idea how the original repo's Debian packages are supposed to be built, it
doesn't seem to work for me. It relies on at least 3 branches (including
a "pristine tar" branch).
Have added a (possibly simpler) set of Debian branches based on
["Debianization with git-buildpackage"](http://www.lpenz.org/articles/debgit/index.html).

## First time setup

Tedious and fiddly, but only need be done once.

1\. Install build and packaging tools:

```
apt-get install \
  autoconf \
  automake \
  dh-make \
  git-buildpackage \
  libdistro-info-perl
```

(All needed? Dunno.)

2\. This process creates a lot of Debian-specific files in the parent directory of your
git repo, it can make things cleaner to do something like

```
mkdir WORK
git clone --dissociate backupninja WORK/backupninja
```

to create a fresh copy.

3\. Follow original release process for updating `configure.ac` and `CHANGELOG.md`.

Ensure `[Unreleased]` section of CHANGELOG.md is up to date and committed.

```
export VERSION=x.y.z
export PACKAGE=backupninja
```

Update version in `configure.ac` and `CHANGELOG.md`:

```
perl -pi -E \
   "s{^AC_INIT\(\[backupninja\],\[[0-9.\-rc]+\],}{AC_INIT([backupninja],[$VERSION],}" \
   configure.ac

RELEASE_DATE=$(LC_ALL=C date '+%Y-%m-%d'); perl -pi -E \
   "s{^## \[Unreleased\].*}{## [$VERSION] - $RELEASE_DATE}" \
   CHANGELOG.md
```

4\.  Commit and tag the changes (produces a tag `backupninja-X.Y.Z`)

```
git commit configure.ac CHANGELOG.md \
    -m "Releasing backupninja $VERSION" && \
git clean -fdx -e .vagrant && \
git tag -a "backupninja-$VERSION" \
    -m "Releasing backupninja $VERSION"
```

5\. create "`.orig.tar.gz`" file:

```
git archive --format=tar --prefix=${PACKAGE}_${VERSION}/ ${PACKAGE}-${VERSION} | gzip -c > ../${PACKAGE}_${VERSION}.orig.tar.gz
```

(Just gives us a .tgz as at the `${PACKAGE}-${VERSION}` tag, basically.)

6\. create debian branches.

We prefix each of these branches with "debian-", so it's clearer
why they're here. And we construct them as orphans, so they basically
form a little universe of their own, with changes cherry-picked
from `master`. Makes the repo history less confusing IMO.

```
git checkout --orphan debian-upstream
git rm --cached -r .
git clean -xfd
git commit --allow-empty -m 'Start of debian branches'
git checkout -b debian-debian
```

7\. add `debian` directory

In our case, copied from the original repo's `debian` branch.
For a fresh project, running `dh_make -s -p ${PACKAGE}_${VERSION}`
creates useful templates which can be adapted as needed.

In particular, note that `debian/gbp.conf` should specify the
names of the branches we're using for the debian distro.

e.g.

```
[DEFAULT]
upstream-branch=debian-upstream
debian-branch=debian-debian
```

Then commit with e.g. `git commit -m "debian stuff"`.

8\. Update debian changelog

```
gbp dch --since=master --new-version=${VERSION}-1
```

(`master`, or any tag name should do I think.)

This creates a new "section" in the `debian/changelog`
file. The debian build tools apparently rely on this to
know what version we're current releaseing. Edit it as needed.

Then commit and tag.

```
export DEBIAN_VERSION=$(dpkg-parsechangelog -SVersion)
git commit debian/changelog \
           -m "Releasing backupninja ($DEBIAN_VERSION) to Debian unstable"
```

(`DEBIAN_VERSION` should be something like X.Y.Z-1.)

9\. Use the `orig.tar.gz` file to create debian content and tags.

```
gbp import-orig \
  --no-interactive ../${PACKAGE}_${VERSION}.orig.tar.gz
```

This:

- imports the contents of the .tgz into the `debian-upstream` branch, and
  creates a commit from it
- tags the commit as 'upstream/1.2.2'
- does a merge between `debian-upstream` and `debian-debian`

10\. Build the `.deb` file (plus a bunch of other Debian-specific files)

```
gbp buildpackage -us -uc --git-tag
```

The new .deb file should now be sitting in `..`.

You can install it with e.g. `sudo apt install /path/to/debfile.deb`.

## Later releases

1\. Do normal `master` branch release stuff as before, set VERSION and PACKAGE
env vars, and from `master`, create .orig.tgz file.

See above, finishing with:

```
git archive --format=tar --prefix=${PACKAGE}_${VERSION}/ ${PACKAGE}-${VERSION} | gzip -c > ../${PACKAGE}_${VERSION}.orig.tar.gz
```

2\. Switch to `debian-debian`, and import tgz.

```
git checkout debian-debian
gbp import-orig --no-interactive ../${PACKAGE}_${VERSION}.orig.tar.gz
```


3\. amend debian/changelog.

```
gbp dch --auto
```

should be enough to create new changelog section, but might need tweaking.

3\. Commit new debian version and tag.

```
$ export DEBIAN_VERSION=$(dpkg-parsechangelog -SVersion)
$ git commit debian/changelog \
           -m "Releasing backupninja ($DEBIAN_VERSION) to Debian unstable"
```

4\. Build new `.deb` file

```
gbp buildpackage -us -uc --git-tag
```

