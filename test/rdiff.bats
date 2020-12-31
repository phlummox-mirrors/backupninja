load common

begin_rdiff() {
    apt-get -qq install debootstrap rdiff-backup cstream
    if [ ! -d /var/cache/bntest ]; then
        debootstrap --variant=minbase testing /var/cache/bntest
    fi
}

setup_rdiff() {
    cat << EOF > "${BATS_TMPDIR}/backup.d/test.rdiff"
when = manual
options = --no-carbonfile
nicelevel = 19
testconnect = no
bwlimit = 
ignore_version = no
output_as_info = yes
keep = yes

[source]
label = rdifftest
type = local
keep = yes
include = /var/cache/bntest
exclude = /var/cache/bntest/var

[dest]
type = local
directory = /var/backups
host =
user =
sshoptions = -4
EOF

    chmod 0640 "${BATS_TMPDIR}/backup.d/test.rdiff"
}

finish_rdiff() {
    rm -rf /var/backups/rdifftest
    ssh vagrant@bntest1 "rm -rf /var/backups/rdifftest"
}

@test "local source/dest backup action runs without errors" {
    run backupninja -f "${BATS_TMPDIR}/backupninja.conf" --now --run "${BATS_TMPDIR}/backup.d/test.rdiff"
    [ "$status" -eq 0 ]
    grep -q "Info: FINISHED: 1 actions run. 0 fatal. 0 error. 0 warning." "${BATS_TMPDIR}/log/backupninja.log"
}

@test "remote destination backup action runs without errors" {
    setconfig backup.d/test.rdiff testconnect yes
    setconfig backup.d/test.rdiff bwlimit 1250000
    setconfig backup.d/test.rdiff dest type remote
    setconfig backup.d/test.rdiff dest host bntest1
    setconfig backup.d/test.rdiff dest user vagrant
    run backupninja -f "${BATS_TMPDIR}/backupninja.conf" --now --run "${BATS_TMPDIR}/backup.d/test.rdiff"
    [ "$status" -eq 0 ]
    grep -q "Info: FINISHED: 1 actions run. 0 fatal. 0 error. 0 warning." "${BATS_TMPDIR}/log/backupninja.log"
}

@test "remote destination backup action with '--remove-older-than' runs without errors" {
    setconfig backup.d/test.rdiff source keep 1
    setconfig backup.d/test.rdiff dest type remote
    setconfig backup.d/test.rdiff dest host bntest1
    setconfig backup.d/test.rdiff dest user vagrant
    run backupninja -f "${BATS_TMPDIR}/backupninja.conf" --now --run "${BATS_TMPDIR}/backup.d/test.rdiff"
    [ "$status" -eq 0 ]
    grep -q "Info: FINISHED: 1 actions run. 0 fatal. 0 error. 0 warning." "${BATS_TMPDIR}/log/backupninja.log"
    grep -q "Removing backups older than 1D days succeeded." "${BATS_TMPDIR}/log/backupninja.log" 
}
