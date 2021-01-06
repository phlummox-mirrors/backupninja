load common

begin_tar() {
    apt-get -qq install debootstrap ncompress zstd
    if [ ! -d /var/cache/bntest ]; then
        debootstrap --variant=minbase testing /var/cache/bntest
    fi
}

setup_tar() {
    cat << EOF > "${BATS_TMPDIR}/backup.d/test.tar"
when = manual
backupname = bntest
backupdir = /var/backups/tartest
compress = none
includes = /var/cache/bntest
excludes = /var/cache/bntest/var
EOF

    chmod 0640 "${BATS_TMPDIR}/backup.d/test.tar"
}

teardown_tar() {
    cleanup_backups local
}

@test "no compression" {
    runaction
    grep -q "Info: FINISHED: 1 actions run. 0 fatal. 0 error. 0 warning." "${BATS_TMPDIR}/log/backupninja.log"
    archive=$(find /var/backups/tartest -maxdepth 1 -name bntest-\*.tar)
    echo $archive
    [ -s "$archive" ]
    tar xOf "$archive" &> /dev/null
}

@test "compress compression" {
    setconfig backup.d/test.tar compress compress
    runaction
    grep -q "Info: FINISHED: 1 actions run. 0 fatal. 0 error. 0 warning." "${BATS_TMPDIR}/log/backupninja.log"
    archive=$(find /var/backups/tartest -maxdepth 1 -name bntest-\*.tar.compress)
    [ -s "$archive" ]
    tar xZOf "$archive" &> /dev/null
}

@test "gzip compression" {
    setconfig backup.d/test.tar compress gzip
    runaction
    grep -q "Info: FINISHED: 1 actions run. 0 fatal. 0 error. 0 warning." "${BATS_TMPDIR}/log/backupninja.log"
    archive=$(find /var/backups/tartest -maxdepth 1 -name bntest-\*.tgz)
    [ -s "$archive" ]
    tar xzOf "$archive" &> /dev/null
}

@test "bzip2 compression" {
    setconfig backup.d/test.tar compress bzip
    runaction
    grep -q "Info: FINISHED: 1 actions run. 0 fatal. 0 error. 0 warning." "${BATS_TMPDIR}/log/backupninja.log"
    archive=$(find /var/backups/tartest -maxdepth 1 -name bntest-\*.tar.bz2)
    [ -s "$archive" ]
    tar xjOf "$archive" &> /dev/null
}

@test "xz compression" {
    setconfig backup.d/test.tar compress xz
    runaction
    grep -q "Info: FINISHED: 1 actions run. 0 fatal. 0 error. 0 warning." "${BATS_TMPDIR}/log/backupninja.log"
    archive=$(find /var/backups/tartest -maxdepth 1 -name bntest-\*.tar.xz)
    [ -s "$archive" ]
    tar xJOf "$archive" &> /dev/null
}

@test "zstd compression" {
    setconfig backup.d/test.tar compress zstd
    runaction
    grep -q "Info: FINISHED: 1 actions run. 0 fatal. 0 error. 0 warning." "${BATS_TMPDIR}/log/backupninja.log"
    archive=$(find /var/backups/tartest -maxdepth 1 -name bntest-\*.tar.zst)
    [ -s "$archive" ]
    tar --zstd -xOf "$archive" &> /dev/null
}

@test "unknown compression, defaults to gzip" {
    setconfig backup.d/test.tar compress foo
    runaction
    grep -q "Info: FINISHED: 1 actions run. 0 fatal. 0 error. 1 warning." "${BATS_TMPDIR}/log/backupninja.log"
    archive=$(find /var/backups/tartest -maxdepth 1 -name bntest-\*.tgz)
    [ -s "$archive" ]
    tar xzOf "$archive" &> /dev/null
}
