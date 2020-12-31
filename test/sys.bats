load common

begin_sys() {
    apt-get -qq install debconf-utils hwinfo lvm2 cryptsetup-bin parted

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

    # Setup LVM
    pvcreate /dev/sdc
    vgcreate vgtest /dev/sdc
    lvcreate -L 12M -n lvtest vgtest /dev/sdc

    # Setup LUKS
    parted -s /dev/sdd mklabel msdos mkpart p 1MiB 50% mkpart p 50% 100%
    partprobe
    cryptsetup -q --type luks1 luksFormat /dev/sdd1 <<< 123test
    cryptsetup -q --type luks2 luksFormat /dev/sdd2 <<< 123test
    cryptsetup -q --type luks2 luksFormat /dev/sde <<< 123test

    # Do backup
    run backupninja -f "${BATS_TMPDIR}/backupninja.conf" --now --run "${BATS_TMPDIR}/backup.d/test.sys"
}

finish_sys() {
    lvremove -f vgtest/lvtest
    vgremove vgtest
    pvremove /dev/sdc
    dd if=/dev/zero of=/dev/sdc bs=512 count=1 conv=notrunc
    dd if=/dev/zero of=/dev/sdd bs=512 count=1 conv=notrunc
    dd if=/dev/zero of=/dev/sde bs=512 count=1 conv=notrunc
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
    [ -s /var/backups/partitions.sdd.txt ]
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

@test "luksheaders v1 partition backup is made" {
    file /var/backups/luksheader.sdd1.bin | grep -q "LUKS encrypted file"
}

@test "luksheaders v2 partition backup is made" {
    file /var/backups/luksheader.sdd2.bin | grep -q "LUKS encrypted file"
}

@test "luksheaders v2 device backup is made" {
    file /var/backups/luksheader.sde.bin | grep -q "LUKS encrypted file"
}
