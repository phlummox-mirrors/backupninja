apt-get -qq install debconf-utils hwinfo lvm2

load common

test_sys() {
    cat << EOF > "${BATS_TMPDIR}/backup.d/test.sys"
when = manual
packages = no
partitions = no
hardware = no
luksheaders = no
lvm = no
mbr = no
bios = no
EOF

    chmod 0640 "${BATS_TMPDIR}/backup.d/test.sys"
}

setup_lvm() {
    modprobe brd rd_nr=1 rd_size=4585760 max_part=0
    pvcreate /dev/ram0
    vgcreate vgtest /dev/ram0
    lvcreate -L 50M -n lvtest vgtest /dev/ram0
}

teardown_lvm() {
    lvchange -an vgtest/lvtest
    lvremove -f vgtest/lvtest
    vgremove -f vgtest
    pvremove /dev/ram0
    modprobe -r brd
}

setup_luks() {
    modprobe brd rd_nr=1 rd_size=4585760 max_part=0
    cryptsetup -q luksFormat /dev/ram0 <<< 123test
}

teardown_luks() {
    modprobe -r brd
}

@test "system report is created" {
    test_sys
    run backupninja -f "${BATS_TMPDIR}/backupninja.conf" --now --run "${BATS_TMPDIR}/backup.d/test.sys"
    [ "$status" -eq 0 ]
    [ -s /var/backups/sysreport.txt ]
    grep -q '# Determinding your current hostname:' /var/backups/sysreport.txt
    grep -q "Info: FINISHED: 1 actions run. 0 fatal. 0 error. 0 warning." "${BATS_TMPDIR}/log/backupninja.log"
}

@test "packages backup is made" {
    test_sys
    setconfig 'backup.d/test.sys' packages yes
    run backupninja -f "${BATS_TMPDIR}/backupninja.conf" --now --run "${BATS_TMPDIR}/backup.d/test.sys"
    [ "$status" -eq 0 ]
    grep -q "Info: FINISHED: 1 actions run. 0 fatal. 0 error. 0 warning." "${BATS_TMPDIR}/log/backupninja.log"
    [ -s /var/backups/dpkg-selections.txt ]
    [ -s /var/backups/debconfsel.txt ]
}

@test "partitions backup is made" {
    test_sys
    setconfig 'backup.d/test.sys' partitions yes
    run backupninja -f "${BATS_TMPDIR}/backupninja.conf" --now --run "${BATS_TMPDIR}/backup.d/test.sys"
    [ "$status" -eq 0 ]
    [ -s /var/backups/partitions.sda.txt ]
    grep -q "Info: FINISHED: 1 actions run. 0 fatal. 0 error. 0 warning." "${BATS_TMPDIR}/log/backupninja.log"
}

@test "hardware info is made" {
    test_sys
    setconfig 'backup.d/test.sys' hardware yes
    run backupninja -f "${BATS_TMPDIR}/backupninja.conf" --now --run "${BATS_TMPDIR}/backup.d/test.sys"
    [ "$status" -eq 0 ]
    [ -s /var/backups/hardware.txt ]
    grep -q "Info: FINISHED: 1 actions run. 0 fatal. 0 error. 0 warning." "${BATS_TMPDIR}/log/backupninja.log"
}

@test "lvm backup is made" {
    test_sys
    setconfig 'backup.d/test.sys' lvm yes
    setup_lvm
    run backupninja -f "${BATS_TMPDIR}/backupninja.conf" --now --run "${BATS_TMPDIR}/backup.d/test.sys"
    [ "$status" -eq 0 ]
    [ -d /var/backups/lvm ]
    [ -s /var/backups/lvm/vgtest ]
    grep -q 'contents = "Text Format Volume Group"' "/var/backups/lvm/vgtest"
    grep -q "Info: FINISHED: 1 actions run. 0 fatal. 0 error. 0 warning." "${BATS_TMPDIR}/log/backupninja.log"
    teardown_lvm
}

@test "luksheaders backup is made" {
    test_sys
    setconfig 'backup.d/test.sys' luksheaders yes
    setup_luks
    run backupninja -f "${BATS_TMPDIR}/backupninja.conf" --now --run "${BATS_TMPDIR}/backup.d/test.sys"
    [ "$status" -eq 0 ]
    file /var/backups/luksheader.ram0.bin | grep -q "LUKS encrypted file"
    grep -q "Info: FINISHED: 1 actions run. 0 fatal. 0 error. 0 warning." "${BATS_TMPDIR}/log/backupninja.log"
    teardown_luks
}

