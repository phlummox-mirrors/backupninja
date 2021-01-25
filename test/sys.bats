load common

begin_sys() {
    apt-get -qq install debconf-utils hwinfo lvm2 cryptsetup-bin parted

    cat << EOF > "${BATS_TMPDIR}/backup.d/test.sys"
when = manual
parentdir = $BN_BACKUPDIR
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
}

finish_sys() {
    # remove test artifacts
    rm -rf ${BN_BACKUPDIR}/*
    # cleanup lvm
    lvremove -f vgtest/lvtest
    vgremove vgtest
    pvremove /dev/sdc
    # cleanup luks data and partition tables
    dd if=/dev/zero of=/dev/sdc bs=512 count=1 conv=notrunc
    dd if=/dev/zero of=/dev/sdd1 bs=512 count=2048 conv=notrunc
    dd if=/dev/zero of=/dev/sdd2 bs=512 count=2048 conv=notrunc
    dd if=/dev/zero of=/dev/sdd bs=512 count=1 conv=notrunc
    dd if=/dev/zero of=/dev/sde bs=512 count=2048 conv=notrunc
    partprobe
}

@test "action runs without errors" {
    runaction
    greplog "Info: FINISHED: 1 actions run. 0 fatal. 0 error. 0 warning."
}

@test "system report is created" {
    [ -s "${BN_BACKUPDIR}/sysreport.txt" ]
}

@test "packages backup is made" {
    [ -s "${BN_BACKUPDIR}/dpkg-selections.txt" ]
    [ -s "${BN_BACKUPDIR}/debconfsel.txt" ]
}

@test "partitions backup is made" {
    [ -s "${BN_BACKUPDIR}/partitions.sda.txt" ]
    [ -s "${BN_BACKUPDIR}/partitions.sdd.txt" ]
}

@test "mbr backup is made" {
    [ -s "${BN_BACKUPDIR}/mbr.sda.bin" ]
    file "${BN_BACKUPDIR}/mbr.sda.bin" | grep -q "DOS/MBR boot sector"
}

@test "hardware info backup is made" {
    [ -s "${BN_BACKUPDIR}/hardware.txt" ]
}

@test "lvm backup is made" {
    [ -d "${BN_BACKUPDIR}/lvm" ]
    [ -s "${BN_BACKUPDIR}/lvm/vgtest" ]
    grep -q 'contents = "Text Format Volume Group"' "${BN_BACKUPDIR}/lvm/vgtest"
}

@test "luksheaders v1 partition backup is made" {
    file "${BN_BACKUPDIR}/luksheader.sdd1.bin" | grep -q "LUKS encrypted file"
}

@test "luksheaders v2 partition backup is made" {
    file "${BN_BACKUPDIR}/luksheader.sdd2.bin" | grep -q "LUKS encrypted file"
}

@test "luksheaders v2 device backup is made" {
    file "${BN_BACKUPDIR}/luksheader.sde.bin" | grep -q "LUKS encrypted file"
}
