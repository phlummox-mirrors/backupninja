
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

[dup-example-l9]: https://github.com/phlummox-patches/backupninja/blob/backupninja-1.2.1/examples/example.dup#L9
[dup-conf-l8]: https://github.com/phlummox-patches/backupninja/blob/backupninja-1.2.1/handlers/dup.in#L8

This patch adds that feature.
[luks-merge]: https://0xacab.org/liberate/backupninja/-/merge_requests/58
[luks-bug]: https://0xacab.org/liberate/backupninja/-/issues/11333

