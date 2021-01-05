setup() {

    # declare some constants
    readonly BN_REMOTEUSER="vagrant"
    readonly BN_REMOTEHOST="bntest1"
    readonly BN_BACKUPDIR="/var/backups"
    readonly BN_SRCDIR="/var/cache/bntest"

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

# set parameter/value in action config file
setconfig() {
    if [ -z $4 ]; then
        # default section
        crudini --set "${BATS_TMPDIR}/$1" '' $2 "$3"
    else
        # named section
        crudini --set "${BATS_TMPDIR}/$1" $2 $3 "$4"
    fi
}

# special-case for repeating config parameters
# crudini doesn't support those
# (used for include and exclude parameters)
setconfig_repeat() {
    conffile="${BATS_TMPDIR}/$1"
    param="$2"
    shift; shift;
    for p in "$@"; do
        conf="${conf}${param} = ${p}\n"
    done
    sed -i "s#^${param} =.*#${conf}#" "${conffile}"
}

# delete config parameter
delconfig() {
    if [ -z $3 ]; then
        # default section
        crudini --del "${BATS_TMPDIR}/$1" '' $2
    else
        # named section
        crudini --del "${BATS_TMPDIR}/$1" $2 $3
    fi
}

# execute command on remote vagrant host
remote_command() {
    ssh "${BN_REMOTEUSER}@${BN_REMOTEHOST}" "$1"
}

# remove backup test artifacts
cleanup_backups() {
    for c in "$@"; do
        case "$c" in
            "local")
                umount "$BN_BACKUPDIR"
                mount -t tmpfs tmpfs "$BN_BACKUPDIR"
                ;;
            "remote")
                remote_command "sudo umount \"$BN_BACKUPDIR\""
                remote_command "sudo mount -t tmpfs tmpfs \"$BN_BACKUPDIR\""
                ;;
        esac
    done
}

# run backupninja action, removing previous log file if exists
runaction() {
    if [ -f "${BATS_TMPDIR}/backup.d/${1}" ]; then
        [ -f "${BATS_TMPDIR}/log/backupninja.log" ] && rm -f "${BATS_TMPDIR}/log/backupninja.log"
        run backupninja -f "${BATS_TMPDIR}/backupninja.conf" --now --run "${BATS_TMPDIR}/backup.d/${1}"
    else
        echo "action file not found: ${BATS_TMPDIR}/backup.d/${1}"
        false
    fi
}

# run backupninja action in test mode, removing previous log file if exist
testaction() {
    if [ -f "${BATS_TMPDIR}/backup.d/${1}" ]; then
        [ -f "${BATS_TMPDIR}/log/backupninja.log" ] && rm -f "${BATS_TMPDIR}/log/backupninja.log"
        run backupninja -f "${BATS_TMPDIR}/backupninja.conf" --now --test --run "${BATS_TMPDIR}/backup.d/${1}"
    else
        echo "action file not found: ${BATS_TMPDIR}/backup.d/${1}"
        false
    fi
}

# grep the backupninja log
greplog() {
    if [ -z "$2" ]; then
        grep -q "$1" "${BATS_TMPDIR}/log/backupninja.log"
    else
        # grep line following previous match
        grep -A1 "$1" "${BATS_TMPDIR}/log/backupninja.log" | tail -n1 | grep -q -- "$2"
    fi
}


not_greplog() {
    if [ -z "$2" ]; then
        ! grep -q "$1" "${BATS_TMPDIR}/log/backupninja.log"
    else
        # grep line following previous match
        ! (grep -A1 "$1" "${BATS_TMPDIR}/log/backupninja.log" | tail -n1 | grep -q -- "$2")
    fi
}

makegpgkeys() {
    # encryption key
    run gpg --keyid-format long -k encrypt@bntest0 2>/dev/null
    if [ "$status" -eq 2 ]; then
        gpg --batch --gen-key <<"        EOF"
            Key-Type: 1
            Key-Length: 2048
            Subkey-Type: 1
            Subkey-Length: 2048
            Name-Real: Encrypt key
            Name-Email: encrypt@bntest0
            Expire-Date: 0
            Passphrase: 123encrypt
        EOF
    fi
    BN_ENCRYPTKEY=$(gpg --keyid-format long -k encrypt@bntest0 | sed -n '2p' | grep -o '\S\+')
    export BN_ENCRYPTKEY
    # signing key
    run gpg --keyid-format long -k sign@bntest0 2>/dev/null
    if [ "$status" -eq 2 ]; then
        gpg --batch --gen-key <<"        EOF"
            Key-Type: 1
            Key-Length: 2048
            Subkey-Type: 1
            Subkey-Length: 2048
            Name-Real: Sign key
            Name-Email: sign@bntest0
            Expire-Date: 0
            Passphrase: 123sign
        EOF
    fi
    BN_SIGNKEY=$(gpg --keyid-format long -k sign@bntest0 | sed -n '2p' | grep -o '\S\+')
    export BN_SIGNKEY
}
