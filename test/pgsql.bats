load common

begin_pgsql() {
    apt-get -qq install postgresql
    systemctl is-active postgresql || systemctl start postgresql
    sudo -u postgres createuser --superuser root
    createdb bntest_p8Cz8k
    createdb bntest_v11vJj
    zcat "${BATS_TEST_DIRNAME}/samples/bntest_p8Cz8k.psql.gz" | psql -d bntest_p8Cz8k
    zcat "${BATS_TEST_DIRNAME}/samples/bntest_v11vJj.psql.gz" | psql -d bntest_v11vJj
}

setup_pgsql() {
    cat << EOF > "${BATS_TMPDIR}/backup.d/test.pgsql"
databases = all
backupdir = ${BN_BACKUPDIR}/postgres
compress = yes
format = plain
EOF

    chmod 0640 "${BATS_TMPDIR}/backup.d/test.pgsql"
}

finish_pgsql() {
    dropdb bntest_p8Cz8k
    dropdb bntest_v11vJj
    sudo -u postgres dropuser root
    systemctl stop postgresql
}

teardown_pgsql() {
    cleanup_backups local
}

@test "plain: exports all databases, with compression" {
    setconfig backup.d/test.pgsql databases all
    setconfig backup.d/test.pgsql compress yes
    setconfig backup.d/test.pgsql format plain
    runaction test.pgsql
    [ "$status" -eq 0 ]
    gzip -tq "${BN_BACKUPDIR}/postgres/bntest0-all.sql.gz"
}

@test "plain: exports all databases, without compression" {
    setconfig backup.d/test.pgsql databases all
    setconfig backup.d/test.pgsql compress no
    setconfig backup.d/test.pgsql format plain
    runaction test.pgsql
    [ "$status" -eq 0 ]
    [ -s "${BN_BACKUPDIR}/postgres/bntest0-all.sql" ]
}

@test "plain: exports specific database, with compression" {
    setconfig backup.d/test.pgsql databases bntest_v11vJj
    setconfig backup.d/test.pgsql compress yes
    setconfig backup.d/test.pgsql format plain
    runaction test.pgsql
    [ "$status" -eq 0 ]
    gzip -tq "${BN_BACKUPDIR}/postgres/bntest_v11vJj.sql.gz"
    [ "$(zgrep -c -e '^COPY' ${BN_BACKUPDIR}/postgres/bntest_v11vJj.sql.gz)" -eq 68 ]
    [ ! -e "${BN_BACKUPDIR}/postgres/bntest_p8Cz8k.sql.gz" ]
}

@test "plain: exports specific database, without compression" {
    setconfig backup.d/test.pgsql databases bntest_v11vJj
    setconfig backup.d/test.pgsql compress no
    setconfig backup.d/test.pgsql format plain
    runaction test.pgsql
    [ "$status" -eq 0 ]
    [ -s "${BN_BACKUPDIR}/postgres/bntest_v11vJj.sql" ]
    [ "$(grep -c -e '^COPY' ${BN_BACKUPDIR}/postgres/bntest_v11vJj.sql)" -eq 68 ]
    [ ! -e "${BN_BACKUPDIR}/postgres/bntest_p8Cz8k.sql" ]
}

@test "tar: exports all databases, with compression" {
    setconfig backup.d/test.pgsql databases all
    setconfig backup.d/test.pgsql compress yes
    setconfig backup.d/test.pgsql format tar
    runaction test.pgsql
    [ "$status" -eq 0 ]
    gzip -tq "${BN_BACKUPDIR}/postgres/bntest_p8Cz8k.pg_dump.gz"
    gzip -tq "${BN_BACKUPDIR}/postgres/bntest_v11vJj.pg_dump.gz"
    gzip -tq "${BN_BACKUPDIR}/postgres/globals.sql.gz"
}

@test "tar: exports all databases, without compression" {
    setconfig backup.d/test.pgsql databases all
    setconfig backup.d/test.pgsql compress no
    setconfig backup.d/test.pgsql format tar
    runaction test.pgsql
    [ "$status" -eq 0 ]
    [ -s "${BN_BACKUPDIR}/postgres/bntest_p8Cz8k.pg_dump" ]
    [ -s "${BN_BACKUPDIR}/postgres/bntest_v11vJj.pg_dump" ]
    file ${BN_BACKUPDIR}/postgres/bntest_p8Cz8k.pg_dump | grep "POSIX tar archive"
    file ${BN_BACKUPDIR}/postgres/bntest_v11vJj.pg_dump | grep "POSIX tar archive"
    [ -s "${BN_BACKUPDIR}/postgres/globals.sql" ]
}

@test "tar: exports specific database, with compression" {
    setconfig backup.d/test.pgsql databases bntest_v11vJj
    setconfig backup.d/test.pgsql compress yes
    setconfig backup.d/test.pgsql format tar
    runaction test.pgsql
    [ "$status" -eq 0 ]
    gzip -tq "${BN_BACKUPDIR}/postgres/bntest_v11vJj.pg_dump.gz"
    [ ! -e "${BN_BACKUPDIR}/postgres/bntest_p8Cz8k.pg_dump.gz" ]
    [ ! -e "${BN_BACKUPDIR}/postgres/globals.sql.gz" ]
}

@test "tar: exports specific database, without compression" {
    setconfig backup.d/test.pgsql databases bntest_v11vJj
    setconfig backup.d/test.pgsql compress no
    setconfig backup.d/test.pgsql format tar
    runaction test.pgsql
    [ "$status" -eq 0 ]
    [ -s "${BN_BACKUPDIR}/postgres/bntest_v11vJj.pg_dump" ]
    file ${BN_BACKUPDIR}/postgres/bntest_v11vJj.pg_dump | grep -q "POSIX tar archive"
    [ ! -e "${BN_BACKUPDIR}/postgres/bntest_p8Cz8k.pg_dump" ]
    [ ! -e "${BN_BACKUPDIR}/postgres/globals.sql" ]
}

@test "custom: exports all databases, with compression" {
    setconfig backup.d/test.pgsql databases all
    setconfig backup.d/test.pgsql compress yes
    setconfig backup.d/test.pgsql format custom
    runaction test.pgsql
    [ "$status" -eq 0 ]
    gzip -tq "${BN_BACKUPDIR}/postgres/bntest_p8Cz8k.pg_dump.gz"
    gzip -tq "${BN_BACKUPDIR}/postgres/bntest_v11vJj.pg_dump.gz"
    gzip -tq "${BN_BACKUPDIR}/postgres/globals.sql.gz"
}

@test "custom: exports all databases, without compression" {
    setconfig backup.d/test.pgsql databases all
    setconfig backup.d/test.pgsql compress no
    setconfig backup.d/test.pgsql format custom
    runaction test.pgsql
    [ "$status" -eq 0 ]
    [ -s "${BN_BACKUPDIR}/postgres/bntest_p8Cz8k.pg_dump" ]
    [ -s "${BN_BACKUPDIR}/postgres/bntest_v11vJj.pg_dump" ]
    file "${BN_BACKUPDIR}/postgres/bntest_p8Cz8k.pg_dump" | grep -q "PostgreSQL custom database dump"
    file "${BN_BACKUPDIR}/postgres/bntest_v11vJj.pg_dump" | grep -q "PostgreSQL custom database dump"
    [ -s "${BN_BACKUPDIR}/postgres/globals.sql" ]
}

@test "custom: exports specific database, with compression" {
    setconfig backup.d/test.pgsql databases bntest_v11vJj
    setconfig backup.d/test.pgsql compress yes
    setconfig backup.d/test.pgsql format custom
    runaction test.pgsql
    [ "$status" -eq 0 ]
    gzip -tq "${BN_BACKUPDIR}/postgres/bntest_v11vJj.pg_dump.gz"
    [ ! -e "${BN_BACKUPDIR}/postgres/bntest_p8Cz8k.pg_dump.gz" ]
    [ ! -e "${BN_BACKUPDIR}/postgres/globals.sql.gz" ]
}

@test "custom: exports specific database, without compression" {
    setconfig backup.d/test.pgsql databases bntest_v11vJj
    setconfig backup.d/test.pgsql compress no
    setconfig backup.d/test.pgsql format custom
    runaction test.pgsql
    [ "$status" -eq 0 ]
    [ -s "${BN_BACKUPDIR}/postgres/bntest_v11vJj.pg_dump" ]
    file "${BN_BACKUPDIR}/postgres/bntest_v11vJj.pg_dump" | grep -q "PostgreSQL custom database dump"
    [ ! -e "${BN_BACKUPDIR}/postgres/bntest_p8Cz8k.pg_dump" ]
    [ ! -e "${BN_BACKUPDIR}/postgres/globals.sql" ]
}


