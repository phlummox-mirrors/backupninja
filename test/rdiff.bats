load common

begin_rdiff() {
    apt-get -qq install debootstrap rdiff-backup cstream libfaketime
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
directory = /tmp/backups
host =
user =
sshoptions = -4
EOF

    chmod 0640 "${BATS_TMPDIR}/backup.d/test.rdiff"
}

finish_rdiff() {
    rm -rf /tmp/backups/rdifftest
    ssh vagrant@bntest1 "rm -rf /tmp/backups/rdifftest"
}

@test "local source/dest backup action runs without errors" {
    run backupninja -f "${BATS_TMPDIR}/backupninja.conf" --now --run "${BATS_TMPDIR}/backup.d/test.rdiff"
    [ "$status" -eq 0 ]
    grep -q "Info: FINISHED: 1 actions run. 0 fatal. 0 error. 0 warning." "${BATS_TMPDIR}/log/backupninja.log"
}

@test "verify if 'options' parameter is reflected in backup command" {
    grep "Debug: /usr/bin/rdiff-backup" "${BATS_TMPDIR}/_backupninja.log" | grep -q -- --no-carbonfile
}

@test "verify if 'include' parameter is reflected in backup command" {
    grep "Debug: /usr/bin/rdiff-backup" "${BATS_TMPDIR}/_backupninja.log" | grep -q -- "--include '/var/cache/bntest'"
}

@test "verify if 'exclude' parameter is reflected in backup command" {
    grep "Debug: /usr/bin/rdiff-backup" "${BATS_TMPDIR}/_backupninja.log" | grep -q -- "--exclude '/var/cache/bntest/var'"
}

@test "verify if 'output_as_info' parameter is reflected in log" {
    grep "[ Session statistics ]" "${BATS_TMPDIR}/_backupninja.log" | grep -q "Info: "
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

@test "verify if 'testconnect' parameter is reflected in log" {
    grep -q "Debug: Connected to bntest1 as vagrant successfully" "${BATS_TMPDIR}/_backupninja.log"
}

@test "verify if 'ignore_version' parameter is reflected in log" {
    grep -q "Debug: /usr/bin/rdiff-backup -V" "${BATS_TMPDIR}/_backupninja.log"
}

@test "verify if 'bwlimit' parameter is reflected in log" {
    grep -q "cstream -t 1250000" "${BATS_TMPDIR}/_backupninja.log"
}

@test "verify if 'sshoptions' parameter is reflected in log" {
    grep -q "ssh -4" "${BATS_TMPDIR}/_backupninja.log"
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
