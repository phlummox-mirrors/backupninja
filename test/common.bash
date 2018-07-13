setup() {
    # Write a basic config file
    cat << EOF > "${BATS_TMPDIR}/backupninja.conf"
when = manual
loglevel = 4
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

    mkdir "${BATS_TMPDIR}/log" "${BATS_TMPDIR}/backup.d"
    chmod 0750 "${BATS_TMPDIR}/backup.d"
}

teardown() {
    # Clean up
    rm -rf "${BATS_TMPDIR}/backupninja.conf" \
        "${BATS_TMPDIR}/log" \
        "${BATS_TMPDIR}/backup.d" \
        /var/mail/vagrant \
        /var/backups/*
}

setconfig() {
    if grep -q "$2 =" "${BATS_TMPDIR}/$1"; then
        sed -i "s/^$2.*/$2 = $3/" "${BATS_TMPDIR}/$1"
    else
        echo "$2 = $3/" >> "${BATS_TMPDIR}/$1"
    fi
}
