load common

setup_sh() {
    cat << EOF > "${BATS_TMPDIR}/backup.d/test.sh"
!#/bin/sh
touch /var/backups/test_sh
EOF

    chmod 0750 "${BATS_TMPDIR}/backup.d/test.sh"
}

@test "sh: runs and creates file" {
    run backupninja -f "${BATS_TMPDIR}/backupninja.conf" --now --run "${BATS_TMPDIR}/backup.d/test.sh"
    [ "$status" -eq 0 ]
    [ -f /var/backups/test_sh ]
    grep -q "Info: FINISHED: 1 actions run. 0 fatal. 0 error. 0 warning." "${BATS_TMPDIR}/log/backupninja.log"
}
