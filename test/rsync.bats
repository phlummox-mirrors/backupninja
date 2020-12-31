load common

begin_rsync() {
    apt-get -qq install debootstrap rsync
    if [ ! -d /var/cache/bntest ]; then
        debootstrap --variant=minbase testing /var/cache/bntest
    fi
}

setup_rsync() {
    cat << EOF > "${BATS_TMPDIR}/backup.d/test.rsync"
when = manual

[general]
log = ${BATS_TMPDIR}/log/rsync.log
mountpoint = /var/backups
backupdir = 
format = 

[source]
from = local
include = /var/cache/bntest
exclude = /var/cache/bntest/var

[dest]
dest = local
host =
user =
id_file = /root/.ssh/id_ed25519
EOF

    chmod 0640 "${BATS_TMPDIR}/backup.d/test.rsync"
}

finish_rsync() {
    cleanup_backups
    #ssh vagrant@bntest1 "rm -rf /var/backups/rsynctest.*"
}

@test "short: local source/dest backup action runs without errors" {
    cleanup_backups
    setconfig backup.d/test.rsync general format short
    setconfig backup.d/test.rsync general backupdir rsynctest.short
    mkdir -p /var/backups/rsynctest.short/var/cache/bntest/bntest.0
    run backupninja -f "${BATS_TMPDIR}/backupninja.conf" --now --run "${BATS_TMPDIR}/backup.d/test.rsync"
    [ "$status" -eq 0 ]
    grep -q "Info: FINISHED: 1 actions run. 0 fatal. 0 error. 0 warning." "${BATS_TMPDIR}/log/backupninja.log"
}

@test "short: local source/dest backup exists" {
    skip "not implemented"
}

@test "short: local source/dest rsync options as expected" {
    skip "not implemented"
}

@test "short: local source/dest backup ingests update" {
    skip "not implemented"
}

@test "short: local source/dest backup rotation" {
    skip "not implemented"
}

@test "short: local source/dest backup appears valid" {
    skip "not implemented"
}

@test "long: local source/dest backup action runs without errors" {
    cleanup_backups
    setconfig backup.d/test.rsync general format long
    setconfig backup.d/test.rsync general backupdir rsynctest.long
    mkdir -p /var/backups/rsynctest.long/var/cache/bntest/bntest/daily.1
    run backupninja -f "${BATS_TMPDIR}/backupninja.conf" --now --run "${BATS_TMPDIR}/backup.d/test.rsync"
    [ "$status" -eq 0 ]
    grep -q "Info: FINISHED: 1 actions run. 0 fatal. 0 error. 0 warning." "${BATS_TMPDIR}/log/backupninja.log"
}

@test "long: local source/dest backup exists" {
    skip "not implemented"
}

@test "long: local source/dest rsync options as expected" {
    skip "not implemented"
}

@test "long: local source/dest backup ingests update" {
    skip "not implemented"
}

@test "long: local source/dest backup rotation" {
    skip "not implemented"
}

@test "long: local source/dest backup appears valid" {
    skip "not implemented"
}

@test "mirror: local source/dest backup action runs without errors" {
    cleanup_backups
    setconfig backup.d/test.rsync general format mirror
    setconfig backup.d/test.rsync general backupdir rsynctest.mirror
    mkdir -p /var/backups/rsynctest.mirror/var/cache/bntest
    run backupninja -f "${BATS_TMPDIR}/backupninja.conf" --now --run "${BATS_TMPDIR}/backup.d/test.rsync"
    [ "$status" -eq 0 ]
    grep -q "Info: FINISHED: 1 actions run. 0 fatal. 0 error. 0 warning." "${BATS_TMPDIR}/log/backupninja.log"
}

@test "mirror: local source/dest backup exists" {
    skip "not implemented"
}

@test "mirror: local source/dest rsync options as expected" {
    skip "not implemented"
}

@test "mirror: local source/dest backup ingests update" {
    skip "not implemented"
}

@test "mirror: local source/dest backup appears valid" {
    skip "not implemented"
}

@test "short: remote dest backup action runs without errors" {
    cleanup_remote_backups
    setconfig backup.d/test.rsync general format short
    setconfig backup.d/test.rsync general backupdir rsynctest.short
    setconfig backup.d/test.rsync dest dest remote
    setconfig backup.d/test.rsync dest host bntest1
    setconfig backup.d/test.rsync dest user vagrant
    cleanup_remote_backups
    remote_command "mkdir -p /var/backups/rsynctest.short/var/cache/bntest/bntest.0"
    run backupninja -f "${BATS_TMPDIR}/backupninja.conf" --now --run "${BATS_TMPDIR}/backup.d/test.rsync"
    [ "$status" -eq 0 ]
    grep -q "Info: FINISHED: 1 actions run. 0 fatal. 0 error. 0 warning." "${BATS_TMPDIR}/log/backupninja.log"
}

@test "short: remote dest backup exists" {
    skip "not implemented"
}

@test "short: remote dest rsync options as expected" {
    skip "not implemented"
}

@test "short: remote dest backup ingests update" {
    skip "not implemented"
}

@test "short: remote dest backup rotation" {
    skip "not implemented"
}

@test "short: remote dest backup appears valid" {
    skip "not implemented"
}

@test "long: remote dest backup action runs without errors" {
    cleanup_remote_backups
    setconfig backup.d/test.rsync general format long
    setconfig backup.d/test.rsync general backupdir rsynctest.long
    setconfig backup.d/test.rsync dest dest remote
    setconfig backup.d/test.rsync dest host bntest1
    setconfig backup.d/test.rsync dest user vagrant
    remote_command "mkdir -p /var/backups/rsynctest.long/var/cache/bntest/bntest/daily.1"
    run backupninja -f "${BATS_TMPDIR}/backupninja.conf" --now --run "${BATS_TMPDIR}/backup.d/test.rsync"
    [ "$status" -eq 0 ]
    grep -q "Info: FINISHED: 1 actions run. 0 fatal. 0 error. 0 warning." "${BATS_TMPDIR}/log/backupninja.log"
}

@test "long: remote dest backup exists" {
    skip "not implemented"
}

@test "long: remote dest rsync options as expected" {
    skip "not implemented"
}

@test "long: remote dest backup ingests update" {
    skip "not implemented"
}

@test "long: remote dest backup rotation" {
    skip "not implemented"
}

@test "long: remote dest backup appears valid" {
    skip "not implemented"
}

@test "mirror: remote dest backup action runs without errors" {
    cleanup_remote_backups
    setconfig backup.d/test.rsync general format mirror
    setconfig backup.d/test.rsync general backupdir rsynctest.mirror
    setconfig backup.d/test.rsync dest dest remote
    setconfig backup.d/test.rsync dest host bntest1
    setconfig backup.d/test.rsync dest user vagrant
    remote_command "mkdir -p /var/backups/rsynctest.mirror/var/cache/bntest"
    run backupninja -f "${BATS_TMPDIR}/backupninja.conf" --now --run "${BATS_TMPDIR}/backup.d/test.rsync"
    [ "$status" -eq 0 ]
    grep -q "Info: FINISHED: 1 actions run. 0 fatal. 0 error. 0 warning." "${BATS_TMPDIR}/log/backupninja.log"
}

@test "mirror: remote dest backup exists" {
    skip "not implemented"
}

@test "mirror: remote dest rsync options as expected" {
    skip "not implemented"
}

@test "mirror: remote dest backup ingests update" {
    skip "not implemented"
}

@test "mirror: remote dest backup appears valid" {
    skip "not implemented"
}
