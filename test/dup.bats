load common

begin_dup() {
    apt-get -qq install debootstrap duplicity trickle
    if [ ! -d /var/cache/bntest ]; then
        debootstrap --variant=minbase testing "$BN_SRCDIR"
    fi
}

setup_dup() {
    cat << EOF > "${BATS_TMPDIR}/backup.d/test.dup"
when = manual
options =
nicelevel = 0
testconnect = no
ionicelevel =
tmpdir = /tmp

[gpg]
password = 123test
signpassword =
sign =
encryptkey =
signkey =

[source]
include = ${BN_SRCDIR}
exclude = ${BN_SRCDIR}/var

[dest]
incremental = yes
increments = 30
keep = yes
keepincroffulls = all
desturl = file:///${BN_BACKUPDIR}/testdup
sshoptions =
bandwidthlimit = 0
desthost =
destdir = ${BN_BACKUPDIR}/testdup
destuser =
EOF

    chmod 0640 "${BATS_TMPDIR}/backup.d/test.dup"

    # reset duplicity archive-dir
    # default path set by handler is /var/cache/backupninja
    BN_DUPARCHIVEDIR="/var/cache/backupninja"
    export BN_DUPARCHIVEDIR
    [ -d "$BN_DUPARCHIVEDIR" ] && rm -rf "$BN_DUPARCHIVEDIR"
    mkdir -p "$BN_DUPARCHIVEDIR"
}

finish_dup() {
    cleanup_backups local remote

    # cleanup duplicity cache dir
    rm -rf /var/cache/backupninja
    remote_command "sudo rm -rf /var/cache/backupninja"

    # cleanup test gpg keys
    gpg --list-secret-keys \*@bntest0 | grep -e '^\s\+[A-Z0-9]\{40\}' | tr -d ' ' | xargs -L1 sudo gpg --delete-secret-keys --batch --no-tty --yes
    gpg --list-keys \*@bntest0 | grep -e '^\s\+[A-Z0-9]\{40\}' | tr -d ' ' | xargs -L1 sudo gpg --delete-keys --batch --no-tty --yes
}

@test "check ssh connection test" {
    setconfig backup.d/test.dup testconnect yes
    setconfig backup.d/test.dup dest destuser $BN_REMOTEUSER
    setconfig backup.d/test.dup dest desthost $BN_REMOTEHOST
    delconfig backup.d/test.dup dest desturl
    testaction test.dup
    [ "$status" -eq 0 ]
    greplog "Debug: Connected to ${BN_REMOTEHOST} as ${BN_REMOTEUSER} successfully$"
}

@test "check config parameter nicelevel" {
    # nicelevel is 0 by default
    delconfig backup.d/test.dup nicelevel
    testaction test.dup
    [ "$status" -eq 0 ]
    greplog 'Debug: executing duplicity$' '\bnice -n 0\b'

    # nicelevel is defined
    setconfig backup.d/test.dup nicelevel -19
    testaction test.dup
    [ "$status" -eq 0 ]
    greplog 'Debug: executing duplicity$' '\bnice -n -19\b'
}

@test "check config parameter ionicelevel" {
    # no ionice by default
    delconfig backup.d/test.dup ionicelevel
    testaction test.dup
    [ "$status" -eq 0 ]
    not_greplog 'Debug: executing duplicity$' '\bionice -c2\b'

    # acceptable value
    setconfig backup.d/test.dup ionicelevel 7
    testaction test.dup
    [ "$status" -eq 0 ]
    greplog 'Debug: executing duplicity$' '\bionice -c2 -n 7\b'

    # unacceptable value
    setconfig backup.d/test.dup ionicelevel 10
    testaction test.dup
    [ "$status" -eq 0 ]
    greplog 'Fatal: The value of ionicelevel is expected to be either empty or an integer from 0 to 7. Got: 10$'
}

@test "check config parameter options" {
    setconfig backup.d/test.dup options "--verbosity 8"
    testaction test.dup
    [ "$status" -eq 0 ]
    greplog 'Debug: executing duplicity$' '\s--verbosity 8\b'
}

@test "check config parameter tmpdir" {
    # tmpdir undefined
    delconfig backup.d/test.dup tmpdir
    testaction test.dup
    [ "$status" -eq 0 ]
    not_greplog 'Debug: executing duplicity$' '\s--tmpdir\b'

    # tmpdir defined
    setconfig backup.d/test.dup tmpdir /tmp
    testaction test.dup
    [ "$status" -eq 0 ]
    not_greplog 'Debug: executing duplicity$' '\s--tmpdir /tmp\b'
}

@test "check config parameter source/include" {
    # missing path
    delconfig backup.d/test.dup source include
    testaction test.dup
    [ "$status" -eq 0 ]
    greplog 'Fatal: No source includes specified.$'

    # single path
    setconfig backup.d/test.dup source include "$BN_SRCDIR"
    testaction test.dup
    [ "$status" -eq 0 ]
    greplog 'Debug: executing duplicity$' "\s--include '${BN_SRCDIR}'"

    # multiple paths
    setconfig_repeat backup.d/test.dup source include "$BN_SRCDIR" /foo /bar
    testaction test.dup
    [ "$status" -eq 0 ]
    greplog 'Debug: executing duplicity$' "\s--include '${BN_SRCDIR}' --include '/foo' --include '/bar'\s"
}

@test "check config parameter source/exclude" {
    # absent path
    delconfig backup.d/test.dup source exclude
    testaction test.dup
    [ "$status" -eq 0 ]
    greplog 'Debug: executing duplicity$' "\s--include '${BN_SRCDIR}' --exclude '\*\*' /\s"

    # single path
    setconfig backup.d/test.dup source exclude "${BN_SRCDIR}/var"
    testaction test.dup
    [ "$status" -eq 0 ]
    greplog 'Debug: executing duplicity$' "\s--exclude '${BN_SRCDIR}/var'\s"

    # multiple paths
    setconfig_repeat backup.d/test.dup source exclude "$BN_SRCDIR/var" "$BN_SRCDIR/foo" "$BN_SRCDIR/bar"
    testaction test.dup
    [ "$status" -eq 0 ]
    greplog 'Debug: executing duplicity$' "\s--exclude '${BN_SRCDIR}/var' --exclude '${BN_SRCDIR}/foo' --exclude '${BN_SRCDIR}/bar'\s"
}

@test "check config parameter dest/incremental" {
    # absent parameter, defaults to yes
    delconfig backup.d/test.dup dest incremental
    testaction test.dup
    [ "$status" -eq 0 ]
    greplog 'Debug: executing duplicity$' 'Debug: nice -n 0 LC_ALL=C duplicity   --no-print-statistics'

    # defined, set to yes
    setconfig backup.d/test.dup dest incremental yes
    testaction test.dup
    [ "$status" -eq 0 ]
    greplog 'Debug: executing duplicity$' 'Debug: nice -n 0 LC_ALL=C duplicity   --no-print-statistics'

    # defined, set to no
    setconfig backup.d/test.dup dest incremental no
    testaction test.dup
    [ "$status" -eq 0 ]
    greplog 'Debug: executing duplicity$' 'Debug: nice -n 0 LC_ALL=C duplicity full  --no-print-statistics'
}

@test "check config parameter dest/increments" {
    # absent parameter, defaults to 30
    delconfig backup.d/test.dup dest increments
    testaction test.dup
    [ "$status" -eq 0 ]
    greplog 'Debug: executing duplicity$' '\s--full-if-older-than 30D\b'

    # defined, set to 60
    setconfig backup.d/test.dup dest increments 60
    testaction test.dup
    [ "$status" -eq 0 ]
    greplog 'Debug: executing duplicity$' '\s--full-if-older-than 60D\b'

    # defined, set to keep
    setconfig backup.d/test.dup dest increments keep
    testaction test.dup
    [ "$status" -eq 0 ]
    not_greplog 'Debug: executing duplicity$' '\s--full-if-older-than\s'
}

@test "check config parameter dest/keep" {
    # absent parameter, defaults to 60
    delconfig backup.d/test.dup dest keep
    testaction test.dup
    [ "$status" -eq 0 ]
    greplog 'Debug: executing duplicity remove-older-than$' '\sduplicity remove-older-than 60D\b'

    # defined, set to 180
    setconfig backup.d/test.dup dest keep 180
    testaction test.dup
    [ "$status" -eq 0 ]
    greplog 'Debug: executing duplicity remove-older-than$' '\sduplicity remove-older-than 180D\b'

    # defined, set to yes
    setconfig backup.d/test.dup dest keep yes
    testaction test.dup
    [ "$status" -eq 0 ]
    not_greplog 'Debug: executing duplicity remove-older-than$'
}

@test "check config parameter dest/keepincroffulls" {
    # absent parameter, defaults to all
    setconfig backup.d/test.dup dest keep 30
    delconfig backup.d/test.dup dest keepincroffulls
    testaction test.dup
    [ "$status" -eq 0 ]
    not_greplog 'Debug: executing duplicity remove-all-inc-of-but-n-full$'

    # defined, set to 1
    setconfig backup.d/test.dup dest keep 30
    setconfig backup.d/test.dup dest keepincroffulls 1
    testaction test.dup
    [ "$status" -eq 0 ]
    greplog 'Debug: executing duplicity remove-all-inc-of-but-n-full$' '\sduplicity remove-all-inc-of-but-n-full 1\b'

    # defined, set to all
    setconfig backup.d/test.dup dest keep 30
    setconfig backup.d/test.dup dest keepincroffulls all
    testaction test.dup
    [ "$status" -eq 0 ]
    not_greplog 'Debug: executing duplicity remove-all-inc-of-but-n-full$'
}

@test "check config parameter dest/awsaccesskeyid" {
    skip "not implemented"
}

@test "check config parameter dest/awssecretaccesskey" {
    skip "not implemented"
}

@test "check config parameter dest/cfusername" {
    skip "not implemented"
}

@test "check config parameter dest/cfapikey" {
    skip "not implemented"
}

@test "check config parameter dest/cfauthurl" {
    skip "not implemented"
}

@test "check config parameter dest/dropboxappkey" {
    skip "not implemented"
}

@test "check config parameter dest/dropboxappsecret" {
    skip "not implemented"
}

@test "check config parameter dest/dropboxaccesstoken" {
    skip "not implemented"
}

@test "check config parameter dest/ftp_password" {
    skip "not implemented"
}

@test "check config parameter dest/sshoptions" {
    # undefined
    delconfig backup.d/test.dup dest sshoptions
    testaction test.dup
    [ "$status" -eq 0 ]
    greplog 'Debug: executing duplicity$' "\s--ssh-options ''\s"

    # defined
    setconfig backup.d/test.dup dest sshoptions "-oIdentityFile=/root/.ssh/id_rsa"
    testaction test.dup
    [ "$status" -eq 0 ]
    greplog 'Debug: executing duplicity$' "\s--ssh-options '-oIdentityFile=/root/.ssh/id_rsa'\s"
}

@test "check config parameter dest/bandwidthlimit" {
    # undefined, disabled by default
    delconfig backup.d/test.dup dest bandwidthlimit
    testaction test.dup
    [ "$status" -eq 0 ]
    not_greplog "\btrickle -s\b"

    # defined, set to 250, local file path
    setconfig backup.d/test.dup dest bandwidthlimit 250 
    setconfig backup.d/test.dup dest desturl "file://${BN_BACKUPDIR}/testdup"
    testaction test.dup
    [ "$status" -eq 0 ]
    greplog 'Warning: The bandwidthlimit option is not used with a local file path destination.'
    not_greplog 'Debug: executing duplicity$' "\strickle -s -d 250 -u 250 duplicity\s"

    # defined, set to 250, remote path
    setconfig backup.d/test.dup dest bandwidthlimit 250 
    setconfig backup.d/test.dup dest desturl "sftp://${BN_REMOTEUSER}@${BN_REMOTEHOST}:22${BN_BACKUPDIR}/testdup"
    testaction test.dup
    [ "$status" -eq 0 ]
    greplog 'Debug: executing duplicity$' "\strickle -s -d 250 -u 250 duplicity\s"
}

@test "check config parameter dest/desturl" {
     # undefined desturl
    delconfig backup.d/test.dup dest desturl
    delconfig backup.d/test.dup dest desthost
    testaction test.dup
    [ "$status" -eq 0 ]
    greplog 'Fatal: The destination host (desthost) must be set when desturl is not used.$'

    # desturl, file protocol
    setconfig backup.d/test.dup dest desturl "file://${BN_BACKUPDIR}/testdup"
    testaction test.dup
    [ "$status" -eq 0 ]
    greplog 'Debug: executing duplicity$' "\sfile://${BN_BACKUPDIR}/testdup$"

    # desturl, sftp protocol
    setconfig backup.d/test.dup dest desturl "sftp://${BN_REMOTEUSER}@${BN_REMOTEHOST}:22${BN_BACKUPDIR}/testdup"
    testaction test.dup
    [ "$status" -eq 0 ]
    greplog 'Debug: executing duplicity$' "\ssftp://${BN_REMOTEUSER}@${BN_REMOTEHOST}:22${BN_BACKUPDIR}/testdup$"
}

@test "check config parameters dest/desthost, dest/destuser, dest/destdir" {
    delconfig backup.d/test.dup dest desturl
    setconfig backup.d/test.dup dest desthost "$BN_REMOTEHOST"
    setconfig backup.d/test.dup dest destuser "$BN_REMOTEUSER"
    setconfig backup.d/test.dup dest destdir "$BN_BACKUPDIR/testdup"
    testaction test.dup
    [ "$status" -eq 0 ]
    greplog 'Debug: executing duplicity$' "\sscp://${BN_REMOTEUSER}@${BN_REMOTEHOST}/${BN_BACKUPDIR}/testdup$"
}

@test "create local backup with symmetric encryption" {
    cleanup_backups local
    mkdir -p /var/backups/testdup
    setconfig backup.d/test.dup gpg password 123test
    setconfig backup.d/test.dup dest desturl "file://${BN_BACKUPDIR}/testdup"
    delconfig backup.d/test.dup dest destdir
    runaction test.dup
    [ "$status" -eq 0 ]
    greplog "Debug: Data will be encrypted using symmetric encryption."
    greplog "Info: Duplicity finished successfully."
}

@test "verify local backup with symmetric encryption" {
    export PASSPHRASE="123foo"
    run duplicity verify --archive-dir "$BN_DUPARCHIVEDIR" "file://${BN_BACKUPDIR}/testdup" "$BN_SRCDIR"
    [ "$status" -eq 31 ]
    export PASSPHRASE="123test"
    duplicity verify --archive-dir "$BN_DUPARCHIVEDIR" "file://${BN_BACKUPDIR}/testdup" "$BN_SRCDIR"
}

@test "create local backup with public key encryption, unsigned" {
    makegpgkeys
    cleanup_backups local
    mkdir -p /var/backups/testdup
    setconfig backup.d/test.dup gpg encryptkey "$BN_ENCRYPTKEY"
    setconfig backup.d/test.dup gpg password 123test
    setconfig backup.d/test.dup dest desturl "file://${BN_BACKUPDIR}/testdup"
    delconfig backup.d/test.dup dest destdir
    runaction test.dup
    [ "$status" -eq 0 ]
    greplog "Debug: Data will be encrypted with the GnuPG key $BN_ENCRYPTKEY.$"
    greplog "Debug: Data won't be signed."
    greplog "Info: Duplicity finished successfully."
}

@test "verify local backup with public key encryption, unsigned" {
    gpgconf --reload gpg-agent && export PASSPHRASE="123foo"
    run duplicity verify --archive-dir "$BN_DUPARCHIVEDIR" "file://${BN_BACKUPDIR}/testdup" "$BN_SRCDIR"
    [ "$status" -eq 31 ]
    echo "$output" | grep -q "gpg: public key decryption failed: Bad passphrase"
    gpgconf --reload gpg-agent && export PASSPHRASE="123encrypt"
    duplicity verify --archive-dir "$BN_DUPARCHIVEDIR" "file://${BN_BACKUPDIR}/testdup" "$BN_SRCDIR"
}

@test "create local backup with public key encryption, signed with same key" {
    makegpgkeys
    cleanup_backups local
    mkdir -p /var/backups/testdup
    setconfig backup.d/test.dup gpg encryptkey "$BN_ENCRYPTKEY"
    setconfig backup.d/test.dup gpg password 123encrypt
    setconfig backup.d/test.dup gpg sign yes
    setconfig backup.d/test.dup dest desturl "file://${BN_BACKUPDIR}/testdup"
    delconfig backup.d/test.dup dest destdir
    runaction test.dup
    [ "$status" -eq 0 ]
    greplog "Debug: Data will be encrypted ang signed with the GnuPG key ${BN_ENCRYPTKEY}.$"
    greplog "Info: Duplicity finished successfully."
}

@test "verify local backup with public key encryption, signed with same key" {
    gpgconf --reload gpg-agent && export PASSPHRASE="123foo"
    run duplicity verify --archive-dir "$BN_DUPARCHIVEDIR" "file://${BN_BACKUPDIR}/testdup" "$BN_SRCDIR"
    [ "$status" -eq 31 ]
    echo "$output" | grep -q "gpg: public key decryption failed: Bad passphrase"
    gpgconf --reload gpg-agent && export PASSPHRASE="123encrypt"
    duplicity verify --archive-dir "$BN_DUPARCHIVEDIR" "file://${BN_BACKUPDIR}/testdup" "$BN_SRCDIR"
}

@test "create local backup with public key encryption, signed with different key" {
    makegpgkeys
    cleanup_backups local
    mkdir -p /var/backups/testdup
    setconfig backup.d/test.dup gpg encryptkey "$BN_ENCRYPTKEY"
    setconfig backup.d/test.dup gpg password 123encrypt
    setconfig backup.d/test.dup gpg sign yes
    setconfig backup.d/test.dup gpg signkey "$BN_SIGNKEY"
    setconfig backup.d/test.dup gpg signpassword 123sign
    setconfig backup.d/test.dup dest desturl "file://${BN_BACKUPDIR}/testdup"
    delconfig backup.d/test.dup dest destdir
    runaction test.dup
    [ "$status" -eq 0 ]
    greplog "Debug: Data will be encrypted with the GnuPG key ${BN_ENCRYPTKEY}.$"
    greplog "Debug: Data will be signed with the GnuPG key ${BN_SIGNKEY}.$"
    greplog "Info: Duplicity finished successfully."
}

@test "verify local backup with public key encryption, signed with different key" {
    gpgconf --reload gpg-agent && export PASSPHRASE="123foo" SIGN_PASSPHRASE="123foo"
    run duplicity verify --archive-dir "$BN_DUPARCHIVEDIR" "file://${BN_BACKUPDIR}/testdup" "$BN_SRCDIR"
    [ "$status" -eq 31 ]
    echo "$output" | grep -q "gpg: public key decryption failed: Bad passphrase"
    gpgconf --reload gpg-agent && export PASSPHRASE="123encrypt" SIGN_PASSPHRASE="123sign"
    duplicity verify --archive-dir "$BN_DUPARCHIVEDIR" "file://${BN_BACKUPDIR}/testdup" "$BN_SRCDIR"
}

@test "create remote backup with symmetric encryption" {
    setconfig backup.d/test.dup gpg password 123test
    delconfig backup.d/test.dup dest desturl
    setconfig backup.d/test.dup dest destuser "$BN_REMOTEUSER"
    setconfig backup.d/test.dup dest desthost "$BN_REMOTEHOST"
    setconfig backup.d/test.dup dest destdir "${BN_BACKUPDIR}/testdup"
    cleanup_backups remote
    runaction test.dup
    [ "$status" -eq 0 ]
    greplog "Debug: Data will be encrypted using symmetric encryption."
    greplog "Info: Duplicity finished successfully."
}

@test "verify remote backup with symmetric encryption" {
    export PASSPHRASE="123foo"
    run duplicity verify --archive-dir "$BN_DUPARCHIVEDIR" "scp://${BN_REMOTEUSER}@$BN_REMOTEHOST/${BN_BACKUPDIR}/testdup" "$BN_SRCDIR"
    [ "$status" -eq 31 ]
    export PASSPHRASE="123test"
    duplicity verify --archive-dir "$BN_DUPARCHIVEDIR" "scp://${BN_REMOTEUSER}@$BN_REMOTEHOST/${BN_BACKUPDIR}/testdup" "$BN_SRCDIR"
}

@test "create remote backup with public key encryption, signed with same key" {
    makegpgkeys
    setconfig backup.d/test.dup gpg encryptkey "$BN_ENCRYPTKEY"
    setconfig backup.d/test.dup gpg password 123encrypt
    setconfig backup.d/test.dup gpg sign yes
    delconfig backup.d/test.dup dest desturl
    setconfig backup.d/test.dup dest destuser "$BN_REMOTEUSER"
    setconfig backup.d/test.dup dest desthost "$BN_REMOTEHOST"
    setconfig backup.d/test.dup dest destdir "${BN_BACKUPDIR}/testdup"
    cleanup_backups remote
    runaction test.dup
    [ "$status" -eq 0 ]
    greplog "Debug: Data will be encrypted ang signed with the GnuPG key ${BN_ENCRYPTKEY}.$"
    greplog "Info: Duplicity finished successfully."
}

@test "verify remote backup with public key encryption, signed with same key" {
    gpgconf --reload gpg-agent && export PASSPHRASE="123foo"
    run duplicity verify --archive-dir "$BN_DUPARCHIVEDIR" "scp://${BN_REMOTEUSER}@$BN_REMOTEHOST/${BN_BACKUPDIR}/testdup" "$BN_SRCDIR"
    [ "$status" -eq 31 ]
    echo "$output" | grep -q "gpg: public key decryption failed: Bad passphrase"
    gpgconf --reload gpg-agent && export PASSPHRASE="123encrypt"
    duplicity verify --archive-dir "$BN_DUPARCHIVEDIR" "scp://${BN_REMOTEUSER}@$BN_REMOTEHOST/${BN_BACKUPDIR}/testdup" "$BN_SRCDIR"
}
