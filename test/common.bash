setup() {

    # Write a basic backupninja config file
    cat << EOF > "${BATS_TMPDIR}/backupninja.conf"
when = manual
loglevel = 5
reportemail = root
reportsuccess = yes
reportinfo = no
reportwarning = yes
reportspace = no
reporthost =
reportuser = ninja
reportdirectory = /var/lib/backupninja/reports
admingroup = root
logfile = ${BATS_TMPDIR}/log/backupninja.log
configdirectory = ${BATS_TMPDIR}/backup.d
scriptdirectory = /usr/share/backupninja
libdirectory = /usr/lib/backupninja
usecolors = no
EOF

    # Create backupninja directories
    mkdir "${BATS_TMPDIR}/log" "${BATS_TMPDIR}/backup.d"
    chmod 0750 "${BATS_TMPDIR}/backup.d"

    # Get name of component being tested
    COMP=$(basename -s .bats "${BATS_TEST_FILENAME}")

    # Invoke component-specific general test setup
    # (runs only before the first test case)
    if [[ "$BATS_TEST_NUMBER" -eq 1 ]]; then
        if type "begin_${COMP}" 2>&1 | grep -q "function"; then
            begin_${COMP}
        fi
    fi

    # Invoke component-specific test setup
    if type "setup_${COMP}" 2>&1 | grep -q "function"; then
        setup_${COMP}
    fi
}

teardown() {

    # Print the debug log in case the test case fails
    if [ -f "${BATS_TMPDIR}/log/backupninja.log" ]; then
        echo "cat ${BATS_TMPDIR}/log/backupninja.log :"
        cat "${BATS_TMPDIR}/log/backupninja.log"
        # Copy logfile so it can be examined in subsequent tests
        cp "${BATS_TMPDIR}/log/backupninja.log" "${BATS_TMPDIR}/_backupninja.log"
    else
        echo "backupninja.log not found"
    fi

    # Clean up
    rm -rf "${BATS_TMPDIR}/backupninja.conf" \
        "${BATS_TMPDIR}/log" \
        "${BATS_TMPDIR}/backup.d" \
        /var/mail/vagrant

    # Invoke component-specific test teardown
    if type "teardown_${COMP}" 2>&1 | grep -q "function"; then
        teardown_${COMP}
    fi

    # Invoke component-specific general test teardown
    # (runs only after the last test case)
    if [[ "${#BATS_TEST_NAMES[@]}" -eq "$BATS_TEST_NUMBER" ]]; then
        if type "finish_${COMP}" 2>&1 | grep -q "function"; then
            finish_${COMP}
        fi
    fi
}

setconfig() {
    if [ -z $4 ]; then
        crudini --set "${BATS_TMPDIR}/$1" '' $2 "$3"
    else
        crudini --set "${BATS_TMPDIR}/$1" $2 $3 "$4"
    fi
}
