load common

begin_borg() {
    apt-get -qq install debootstrap borgbackup
    if [ ! -d "$BN_SRCDIR" ]; then
        debootstrap --variant=minbase testing "$BN_SRCDIR"
    fi
}

setup_borg() {
    cat << EOF > "${BATS_TMPDIR}/backup.d/test.borg"
when = manual
testconnect = no
nicelevel = 0
ionicelevel =
bwlimit =

[source]
init = yes
include = ${BN_SRCDIR}
exclude = ${BN_SRCDIR}/var
create_options =
prune = yes
keep = 30d
prune_options =
cache_directory =

[dest]
user =
host = localhost
port = 22
directory = ${BN_BACKUPDIR}/testborg
archive =
compression = lz4
encryption = none
passphrase =
EOF

    chmod 0640 "${BATS_TMPDIR}/backup.d/test.borg"
    rm -rf /root/.cache/borg
}

finish_borg() {
    cleanup_backups local remote
    rm -rf /root/.cache/borg
}

@test "local source/dest backup action runs without errors" {
    cleanup_backups local
    setconfig backup.d/test.borg dest host localhost
    run backupninja -f "${BATS_TMPDIR}/backupninja.conf" --now --run "${BATS_TMPDIR}/backup.d/test.borg"
    [ "$status" -eq 0 ]
    # repository init emits warning
    grep -q "Info: FINISHED: 1 actions run. 0 fatal. 0 error. 1 warning." "${BATS_TMPDIR}/log/backupninja.log"
}

@test "local source/dest backup exists" {
    skip "not implemented"
}

@test "local source/dest borg options as expected" {
    skip "not implemented"
}

@test "local source/dest backup ingests update" {
    skip "not implemented"
}

@test "local source/dest backup appears valid" {
    skip "not implemented"
}

@test "remote dest backup action runs without errors" {
    cleanup_backups remote
    setconfig backup.d/test.borg testconnect yes
    setconfig backup.d/test.borg dest host bntest1
    setconfig backup.d/test.borg dest user vagrant
    run backupninja -f "${BATS_TMPDIR}/backupninja.conf" --now --run "${BATS_TMPDIR}/backup.d/test.borg"
    [ "$status" -eq 0 ]
    # repository init emits warning
    grep -q "Info: FINISHED: 1 actions run. 0 fatal. 0 error. 1 warning." "${BATS_TMPDIR}/log/backupninja.log"
}

@test "remote dest backup exists" {
    skip "not implemented"
}

@test "remote dest borg options as expected" {
    skip "not implemented"
}

@test "remote dest backup ingests update" {
    skip "not implemented"
}

@test "remote dest backup appears valid" {
    skip "not implemented"
}
