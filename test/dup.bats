load common

begin_dup() {
    apt-get -qq install debootstrap duplicity trickle
    if [ ! -d /var/cache/bntest ]; then
        debootstrap --variant=minbase testing /var/cache/bntest
    fi
}

setup_dup() {
    cat << EOF > "${BATS_TMPDIR}/backup.d/test.dup"
when = manual
options = --verbosity 8
nicelevel = 0
testconnect = no
ionicelevel =
tmpdir = /tmp

[gpg]
password = 123vagrant
signpassword =
sign =
encryptkey =
signkey =

[source]
include = /var/cache/bntest
exclude = /var/cache/bntest/var

[dest]
incremental = yes
increments = 30
keep = 60
keepincroffulls = all
desturl =
sshoptions =
bandwidthlimit = 0
desthost =
destdir =
destuser =
EOF

    chmod 0640 "${BATS_TMPDIR}/backup.d/test.dup"
}

finish_dup() {
    cleanup_backups local remote
    rm -rf /var/cache/backupninja
    remote_command "sudo rm -rf /var/cache/backupninja"
}

@test "local source/dest backup action runs without errors" {
    cleanup_backups local
    setconfig backup.d/test.dup dest desturl file:///var/backups/testdup
    mkdir -p /var/backups/testdup /var/cache/backupninja
    run backupninja -f "${BATS_TMPDIR}/backupninja.conf" --now --run "${BATS_TMPDIR}/backup.d/test.dup"
    [ "$status" -eq 0 ]
    grep -q "Info: FINISHED: 1 actions run. 0 fatal. 0 error. 0 warning." "${BATS_TMPDIR}/log/backupninja.log"
}

@test "local source/dest backup exists" {
    skip "not implemented"
}

@test "local source/dest duplicity options as expected" {
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
    setconfig backup.d/test.dup testconnect yes
    setconfig backup.d/test.dup dest desthost bntest1
    setconfig backup.d/test.dup dest destuser vagrant
    setconfig backup.d/test.dup dest destdir /var/backups/testdup
    remote_command "mkdir -p /var/backups/testdup"
    remote_command "sudo mkdir -p /var/cache/backupninja"
    run backupninja -f "${BATS_TMPDIR}/backupninja.conf" --now --run "${BATS_TMPDIR}/backup.d/test.dup"
    [ "$status" -eq 0 ]
    grep -q "Info: FINISHED: 1 actions run. 0 fatal. 0 error. 0 warning." "${BATS_TMPDIR}/log/backupninja.log"
}

@test "remote dest backup exists" {
    skip "not implemented"
}

@test "remote dest duplicity options as expected" {
    skip "not implemented"
}

@test "remote dest backup ingests update" {
    skip "not implemented"
}

@test "remote dest backup appears valid" {
    skip "not implemented"
}
