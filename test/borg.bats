load common

begin_borg() {
    apt-get -qq install debootstrap borgbackup
    if [ ! -d "$BN_SRCDIR" ]; then
        debootstrap --variant=minbase testing "$BN_SRCDIR"
    fi
}

setup_borg() {
    cat << EOF > "${BATS_TMPDIR}/backup.d/test.borg"
when = manual
testconnect = no
nicelevel = 0
ionicelevel =
bwlimit =

[source]
init = yes
include = ${BN_SRCDIR}
exclude = ${BN_SRCDIR}/var
create_options =
prune = yes
keep = 30d
prune_options =
cache_directory =

[dest]
user =
host = localhost
port = 22
directory = ${BN_BACKUPDIR}/testborg
archive =
compression = lz4
encryption = none
passphrase =
EOF

    chmod 0640 "${BATS_TMPDIR}/backup.d/test.borg"
    rm -rf /root/.cache/borg
}

finish_borg() {
    cleanup_backups local remote
    rm -rf /root/.cache/borg
}

@test "ssh connection test" {
    setconfig backup.d/test.borg testconnect yes
    setconfig backup.d/test.borg dest user $BN_REMOTEUSER
    setconfig backup.d/test.borg dest host $BN_REMOTEHOST
    testaction test.borg
    [ "$status" -eq 0 ]
    greplog "Debug: Connected to ${BN_REMOTEHOST} as ${BN_REMOTEUSER} successfully$"
}

@test "nicelevel config parameter" {
    # nicelevel is 0 by default
    delconfig backup.d/test.borg nicelevel
    testaction test.borg
    [ "$status" -eq 0 ]
    greplog 'Debug: executing borg create$' '\bnice -n 0\b'

    # nicelevel is defined
    setconfig backup.d/test.borg nicelevel -19
    testaction test.borg
    [ "$status" -eq 0 ]
    greplog 'Debug: executing borg create$' '\bnice -n -19\b'
}

@test "ionicelevel config parameter" {
    # no ionice by default
    delconfig backup.d/test.borg ionicelevel
    testaction test.borg
    [ "$status" -eq 0 ]
    not_greplog 'Debug: executing borg create$' '\bionice -c2\b'

    # acceptable value
    setconfig backup.d/test.borg ionicelevel 7
    testaction test.borg
    [ "$status" -eq 0 ]
    greplog 'Debug: executing borg create$' '\bionice -c2 -n 7\b'

    # unacceptable value
    setconfig backup.d/test.borg ionicelevel 10
    testaction test.borg
    [ "$status" -eq 0 ]
    greplog 'Fatal: The value of ionicelevel is expected to be either empty or an integer from 0 to 7. Got: 10$'
}

@test "bwlimit config parameter" {
    # no limit by default
    delconfig backup.d/test.borg bwlimit
    testaction test.borg
    [ "$status" -eq 0 ]
    not_greplog 'Debug: executing borg create$' '\s--remote-ratelimit='

    # limit is defined
    setconfig backup.d/test.borg bwlimit 1024
    testaction test.borg
    [ "$status" -eq 0 ]
    greplog 'Debug: executing borg create$' '\s--remote-ratelimit=1024\b'

}

@test "[source] init config parameter" {
    # do repository init by default
    delconfig backup.d/test.borg source init
    testaction test.borg
    [ "$status" -eq 0 ]
    greplog 'Debug: executing borg init$'

    # do repository init 
    setconfig backup.d/test.borg source init yes
    testaction test.borg
    [ "$status" -eq 0 ]
    greplog 'Debug: executing borg init$'

    # don't do repository init 
    setconfig backup.d/test.borg source init no
    testaction test.borg
    [ "$status" -eq 0 ]
    not_greplog 'Debug: executing borg init$'
}

@test "[source] include config parameter" {
    # missing path
    delconfig backup.d/test.borg source include
    testaction test.borg
    [ "$status" -eq 0 ]
    greplog 'Fatal: No source includes specified$'

    # single path
    setconfig backup.d/test.borg source include "$BN_SRCDIR"
    testaction test.borg
    [ "$status" -eq 0 ]
    greplog 'Debug: executing borg create$' "'${BN_SRCDIR}'$"

    # multiple paths
    setconfig_repeat backup.d/test.borg include "$BN_SRCDIR" /foo /bar
    testaction test.borg
    [ "$status" -eq 0 ]
    greplog 'Debug: executing borg create$' "'${BN_SRCDIR}' '/foo' '/bar'$"
}

@test "[source] exclude config parameter" {
    # absent path
    delconfig backup.d/test.borg source exclude
    testaction test.borg
    [ "$status" -eq 0 ]
    not_greplog 'Debug: executing borg create$' "\s--exclude\s"

    # single path
    setconfig backup.d/test.borg source exclude "${BN_SRCDIR}/var"
    testaction test.borg
    [ "$status" -eq 0 ]
    greplog 'Debug: executing borg create$' "\s--exclude '${BN_SRCDIR}/var'\s"

    # multiple paths
    setconfig_repeat backup.d/test.borg exclude "$BN_SRCDIR/var" "$BN_SRCDIR/foo" "$BN_SRCDIR/bar"
    testaction test.borg
    [ "$status" -eq 0 ]
    greplog 'Debug: executing borg create$' "\s--exclude '${BN_SRCDIR}/var' --exclude '${BN_SRCDIR}/foo' --exclude '${BN_SRCDIR}/bar'\s"
}

@test "[source] create_options config parameter" {
    # absent parameter
    delconfig backup.d/test.borg source create_options
    testaction test.borg
    [ "$status" -eq 0 ]
    not_greplog 'Debug: executing borg create$' "\s--create-options\s"

    # defined parameter
    setconfig backup.d/test.borg source create_options "--exclude-caches"
    testaction test.borg
    [ "$status" -eq 0 ]
    greplog 'Debug: executing borg create$' "\s--exclude-caches\b"
}

@test "[source] prune config parameter" {
    # absent parameter, defaults enabled
    delconfig backup.d/test.borg source prune
    testaction test.borg
    [ "$status" -eq 0 ]
    greplog 'Debug: executing borg prune$'

    # defined parameter, enabled
    setconfig backup.d/test.borg source prune yes
    testaction test.borg
    [ "$status" -eq 0 ]
    greplog 'Debug: executing borg prune$'

    # defined parameter, disabled
    setconfig backup.d/test.borg source prune no
    cat "${BATS_TMPDIR}/backup.d/test.borg"
    testaction test.borg
    [ "$status" -eq 0 ]
    not_greplog 'Debug: executing borg prune$'
}

@test "[source] keep config parameter" {
    # absent parameter, defaults to '30d'
    setconfig backup.d/test.borg source prune yes
    delconfig backup.d/test.borg source keep
    testaction test.borg
    [ "$status" -eq 0 ]
    greplog 'Debug: executing borg prune$' '\s--keep-within=30d\b'

    # defined parameter, set to 60d
    setconfig backup.d/test.borg source prune yes
    setconfig backup.d/test.borg source keep 60d
    testaction test.borg
    [ "$status" -eq 0 ]
    greplog 'Debug: executing borg prune$' '\s--keep-within=60d\b'

    # defined parameter, disabled, set to 0
    setconfig backup.d/test.borg source prune yes
    setconfig backup.d/test.borg source keep 0
    cat "${BATS_TMPDIR}/backup.d/test.borg"
    testaction test.borg
    [ "$status" -eq 0 ]
    not_greplog 'Debug: executing borg prune$' '\s--keep-within='
}

@test "[source] prune_options config parameter" {
    # absent parameter
    delconfig backup.d/test.borg source prune_options
    testaction test.borg
    [ "$status" -eq 0 ]
    greplog 'Debug: executing borg prune$' "Debug: borg prune  --keep-within=30d ${BN_BACKUPDIR}/testborg$"

    # defined parameter
    setconfig backup.d/test.borg source prune_options "--save-space"
    testaction test.borg
    [ "$status" -eq 0 ]
    greplog 'Debug: executing borg prune$' '\s--save-space\b'
}

@test "[source] cache_directory config parameter" {
    # absent parameter
    delconfig backup.d/test.borg source cache_directory
    testaction test.borg
    [ "$status" -eq 0 ]
    not_greplog 'Debug: export BORG_CACHE_DIR='

    # defined parameter
    setconfig backup.d/test.borg source cache_directory "/var/cache/borg"
    testaction test.borg
    [ "$status" -eq 0 ]
    greplog 'Debug: export BORG_CACHE_DIR="/var/cache/borg"$'
}

@test "[dest] user config parameter" {
    # absent parameter
    delconfig backup.d/test.borg dest user
    setconfig backup.d/test.borg dest host "$BN_REMOTEHOST"
    testaction test.borg
    [ "$status" -eq 0 ]
    greplog 'Fatal: Destination user not set$'

    # defined parameter
    setconfig backup.d/test.borg dest user "$BN_REMOTEUSER"
    setconfig backup.d/test.borg dest host "$BN_REMOTEHOST"
    testaction test.borg
    [ "$status" -eq 0 ]
    greplog "Debug: ssh -o PasswordAuthentication=no ${BN_REMOTEHOST} -p 22 -l ${BN_REMOTEUSER} 'echo -n 1'"
    greplog 'Debug: executing borg create$' "\bssh://${BN_REMOTEUSER}@${BN_REMOTEHOST}:22${BN_BACKUPDIR}/testborg::"
}

@test "[dest] host config parameter" {
    # absent parameter
    delconfig backup.d/test.borg dest host
    setconfig backup.d/test.borg dest user "$BN_REMOTEUSER"
    testaction test.borg
    [ "$status" -eq 0 ]
    greplog 'Fatal: Destination host not set$'

    # defined parameter
    setconfig backup.d/test.borg dest user "$BN_REMOTEUSER"
    setconfig backup.d/test.borg dest host "$BN_REMOTEHOST"
    testaction test.borg
    [ "$status" -eq 0 ]
    greplog "Debug: ssh -o PasswordAuthentication=no ${BN_REMOTEHOST} -p 22 -l ${BN_REMOTEUSER} 'echo -n 1'"
    greplog 'Debug: executing borg create$' "\bssh://${BN_REMOTEUSER}@${BN_REMOTEHOST}:22${BN_BACKUPDIR}/testborg::"
}

@test "[dest] port config parameter" {
    # absent parameter, defaults to 22
    setconfig backup.d/test.borg dest user "$BN_REMOTEUSER"
    setconfig backup.d/test.borg dest host "$BN_REMOTEHOST"
    delconfig backup.d/test.borg dest port
    testaction test.borg
    [ "$status" -eq 0 ]
    greplog "Debug: ssh -o PasswordAuthentication=no ${BN_REMOTEHOST} -p 22 -l ${BN_REMOTEUSER} 'echo -n 1'"
    greplog 'Debug: executing borg create$' "\bssh://${BN_REMOTEUSER}@${BN_REMOTEHOST}:22${BN_BACKUPDIR}/testborg::"

    # defined parameter
    setconfig backup.d/test.borg dest port 7722
    setconfig backup.d/test.borg dest user "$BN_REMOTEUSER"
    setconfig backup.d/test.borg dest host "$BN_REMOTEHOST"
    testaction test.borg
    [ "$status" -eq 0 ]
    greplog "Debug: ssh -o PasswordAuthentication=no ${BN_REMOTEHOST} -p 7722 -l ${BN_REMOTEUSER} 'echo -n 1'"
    greplog 'Debug: executing borg create$' "\bssh://${BN_REMOTEUSER}@${BN_REMOTEHOST}:7722${BN_BACKUPDIR}/testborg::"
}

@test "[dest] directory config parameter" {
    # absent parameter
    delconfig backup.d/test.borg dest directory
    testaction test.borg
    [ "$status" -eq 0 ]
    greplog 'Fatal: Destination directory not set$'

    # defined parameter
    setconfig backup.d/test.borg dest directory "${BN_BACKUPDIR}/testborg"
    testaction test.borg
    [ "$status" -eq 0 ]
    greplog 'Debug: executing borg create$' "\s${BN_BACKUPDIR}/testborg::"
}

@test "[dest] archive config parameter" {
    # absent parameter, defaults to {now:%Y-%m-%dT%H:%M:%S}
    delconfig backup.d/test.borg dest archive
    testaction test.borg
    [ "$status" -eq 0 ]
    greplog 'Debug: executing borg create$' "\s${BN_BACKUPDIR}/testborg::{now:%Y-%m-%dT%H:%M:%S}"

    # defined parameter
    setconfig backup.d/test.borg dest archive foo
    testaction test.borg
    [ "$status" -eq 0 ]
    greplog 'Debug: executing borg create$' "\s${BN_BACKUPDIR}/testborg::foo"
}

@test "[dest] compression config parameter" {
    # absent parameter, defaults to lz4
    delconfig backup.d/test.borg dest compression
    testaction test.borg
    [ "$status" -eq 0 ]
    greplog 'Debug: executing borg create$' "\s--compression lz4\b"

    # defined parameter
    setconfig backup.d/test.borg dest compression auto,zstd,13
    testaction test.borg
    [ "$status" -eq 0 ]
    greplog 'Debug: executing borg create$' "\s--compression auto,zstd,13\b"
}

@test "create local backup without encryption, test extraction" {
    # no encryption, no passphrase
    setconfig backup.d/test.borg dest archive testarchive
    setconfig backup.d/test.borg dest encryption none
    delconfig backup.d/test.borg dest passphrase
    cleanup_backups local
    runaction test.borg
    [ "$status" -eq 0 ]
    greplog 'Debug: executing borg init$' 'Debug: borg init --encryption=none'
    greplog "Warning: Repository has been initialized"
    unset BORG_PASSPHRASE
    borg extract --dry-run "${BN_BACKUPDIR}/testborg::testarchive"
    [ "$status" -eq 0 ]
}

@test "create local backup with encryption, test extraction" {
    # encryption enabled, wrong passphrase
    setconfig backup.d/test.borg dest archive testarchive
    setconfig backup.d/test.borg dest encryption repokey
    setconfig backup.d/test.borg dest passphrase 123test
    cleanup_backups local
    runaction test.borg
    [ "$status" -eq 0 ]
    greplog 'Debug: executing borg init$' 'Debug: borg init --encryption=repokey'
    greplog "Warning: Repository has been initialized"
    export BORG_PASSPHRASE="123foo"
    run borg extract --dry-run "${BN_BACKUPDIR}/testborg::testarchive"
    [ "$status" -eq 2 ]
    export BORG_PASSPHRASE="123test"
    borg extract --dry-run "${BN_BACKUPDIR}/testborg::testarchive"
}

@test "create remote backup with encryption, test extraction" {
    setconfig backup.d/test.borg dest archive testarchive
    setconfig backup.d/test.borg dest encryption repokey
    setconfig backup.d/test.borg dest passphrase 123test
    setconfig backup.d/test.borg dest host "${BN_REMOTEHOST}"
    setconfig backup.d/test.borg dest user "${BN_REMOTEUSER}"
    cleanup_backups remote
    runaction test.borg
    [ "$status" -eq 0 ]
    greplog 'Debug: executing borg init$' 'Debug: borg init --encryption=repokey'
    greplog "Warning: Repository has been initialized"
    export BORG_PASSPHRASE="123foo"
    run borg extract --dry-run "ssh://${BN_REMOTEUSER}@${BN_REMOTEHOST}:22${BN_BACKUPDIR}/testborg::testarchive"
    [ "$status" -eq 2 ]
    export BORG_PASSPHRASE="123test"
    borg extract --dry-run "ssh://${BN_REMOTEUSER}@${BN_REMOTEHOST}:22${BN_BACKUPDIR}/testborg::testarchive"
}
