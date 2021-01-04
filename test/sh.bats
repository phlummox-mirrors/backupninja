load common

setup_sh() {
    cat << EOF > "${BATS_TMPDIR}/backup.d/test.sh"
!#/bin/sh
when = manual
touch "${BN_BACKUPDIR}/testsh"
EOF

    chmod 0750 "${BATS_TMPDIR}/backup.d/test.sh"
}

teardown_sh() {
    cleanup_backups local
}

@test "sh: runs and creates file" {
    runaction test.sh
    [ "$status" -eq 0 ]
    [ -f "${BN_BACKUPDIR}/testsh" ]
    greplog "Info: FINISHED: 1 actions run. 0 fatal. 0 error. 0 warning."
}

@test "sh: is not executed in test mode" {
    testaction test.sh
    [ "$status" -eq 0 ]
    [ ! -f "${BN_BACKUPDIR}/testsh" ]
    greplog "Info: FINISHED: 1 actions run. 0 fatal. 0 error. 0 warning."
}
