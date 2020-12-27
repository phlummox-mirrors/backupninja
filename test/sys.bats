load common

begin_sys() {
    apt-get -qq install debconf-utils hwinfo lvm2 cryptsetup-bin

    cat << EOF > "${BATS_TMPDIR}/backup.d/test.sys"
when = manual
packages = yes
partitions = yes
hardware = yes
luksheaders = yes
lvm = yes
mbr = yes
bios = no
EOF

    chmod 0640 "${BATS_TMPDIR}/backup.d/test.sys"

    # Create 3 ramdisks
    modprobe brd rd_nr=3 rd_size=20480 max_part=0

    # Setup LVM
    pvcreate /dev/ram0
    vgcreate vgtest /dev/ram0
    lvcreate -L 12M -n lvtest vgtest /dev/ram0

    # Setup LUKS v1 encrypted device
    cryptsetup -q --type luks1 luksFormat /dev/ram1 <<< 123test

    # Setup LUKS v2 encrypted device
    cryptsetup -q --type luks2 luksFormat /dev/ram2 <<< 123test

    # Do backup
    run backupninja -f "${BATS_TMPDIR}/backupninja.conf" --now --run "${BATS_TMPDIR}/backup.d/test.sys"
}

finish_sys() {
    lvremove -f vgtest/lvtest
    vgremove vgtest
    pvremove /dev/ram0
    modprobe -r brd
}

@test "action runs without errors" {
    grep -q "Info: FINISHED: 1 actions run. 0 fatal. 0 error. 0 warning." "${BATS_TMPDIR}/log/backupninja.log"
}

@test "system report is created" {
    [ -s /var/backups/sysreport.txt ]
}

@test "packages backup is made" {
    [ -s /var/backups/dpkg-selections.txt ]
    [ -s /var/backups/debconfsel.txt ]
}

@test "partitions backup is made" {
    [ -s /var/backups/partitions.sda.txt ]
}

@test "mbr backup is made" {
    [ -s /var/backups/mbr.sda.bin ]
    file /var/backups/mbr.sda.bin | grep -q "DOS/MBR boot sector"
}

@test "hardware info backup is made" {
    [ -s /var/backups/hardware.txt ]
}

@test "lvm backup is made" {
    [ -d /var/backups/lvm ]
    [ -s /var/backups/lvm/vgtest ]
    grep -q 'contents = "Text Format Volume Group"' "/var/backups/lvm/vgtest"
}

@test "luksheaders v1 backup is made" {
    file /var/backups/luksheader.ram1.bin | grep -q "LUKS encrypted file"
}

@test "luksheaders v2 backup is made" {
    file /var/backups/luksheader.ram2.bin | grep -q "LUKS encrypted file"
}
