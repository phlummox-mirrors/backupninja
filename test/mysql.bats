load common

begin_mysql() {
    apt-get -qq install default-mysql-server
    systemctl is-active mysql || systemctl start mysql
    zcat "${BATS_TEST_DIRNAME}/samples/bntest_p8Cz8k.sql.gz" | mysql --defaults-file=/etc/mysql/debian.cnf
    zcat "${BATS_TEST_DIRNAME}/samples/bntest_v11vJj.sql.gz" | mysql --defaults-file=/etc/mysql/debian.cnf
}

setup_mysql() {
    cat << EOF > "${BATS_TMPDIR}/backup.d/test.mysql"
databases = all
backupdir = ${BN_BACKUPDIR}/mysql
hotcopy = no
sqldump = yes
compress = yes
EOF

    chmod 0640 "${BATS_TMPDIR}/backup.d/test.mysql"
}

finish_mysql() {
    mysqladmin -f drop bntest_p8Cz8k
    mysqladmin -f drop bntest_v11vJj
    systemctl stop mysql
}

teardown_mysql() {
    cleanup_backups local
}

@test "sqldump: exports all databases, with compression" {
    setconfig backup.d/test.mysql databases all
    setconfig backup.d/test.mysql compress yes
    runaction
    [ -s "${BN_BACKUPDIR}/mysql/sqldump/bntest_p8Cz8k.sql.gz" ]
    [ -s "${BN_BACKUPDIR}/mysql/sqldump/bntest_v11vJj.sql.gz" ]
    [ "$(zgrep -c 'INSERT INTO' ${BN_BACKUPDIR}/mysql/sqldump/bntest_p8Cz8k.sql.gz)" -eq 9 ]
    [ "$(zgrep -c 'INSERT INTO' ${BN_BACKUPDIR}/mysql/sqldump/bntest_v11vJj.sql.gz)" -eq 47 ]
}

@test "sqldump: exports all databases, without compression" {
    setconfig backup.d/test.mysql databases all
    setconfig backup.d/test.mysql compress no
    runaction
    [ -s "${BN_BACKUPDIR}/mysql/sqldump/bntest_p8Cz8k.sql" ]
    [ -s "${BN_BACKUPDIR}/mysql/sqldump/bntest_v11vJj.sql" ]
    [ "$(grep -c 'INSERT INTO' ${BN_BACKUPDIR}/mysql/sqldump/bntest_p8Cz8k.sql)" -eq 9 ]
    [ "$(grep -c 'INSERT INTO' ${BN_BACKUPDIR}/mysql/sqldump/bntest_v11vJj.sql)" -eq 47 ]
}

@test "sqldump: exports specific database" {
    setconfig backup.d/test.mysql databases bntest_v11vJj
    runaction
    [ ! -f ${BN_BACKUPDIR}/mysql/sqldump/bntest_p8Cz8k.sql.gz ]
    [ -s "${BN_BACKUPDIR}/mysql/sqldump/bntest_v11vJj.sql.gz" ]
    [ "$(zgrep -c 'INSERT INTO' ${BN_BACKUPDIR}/mysql/sqldump/bntest_v11vJj.sql.gz)" -eq 47 ]
}

@test "ignores: exports all databases while excluding two tables entirely" {
    setconfig backup.d/test.mysql databases all
    setconfig backup.d/test.mysql ignores "bntest_v11vJj.cache_data bntest_v11vJj.cache_entity"
    runaction
    [ -s "${BN_BACKUPDIR}/mysql/sqldump/bntest_p8Cz8k.sql.gz" ]
    [ "$(zgrep -c 'INSERT INTO' ${BN_BACKUPDIR}/mysql/sqldump/bntest_p8Cz8k.sql.gz)" -eq 9 ]
    [ -s "${BN_BACKUPDIR}/mysql/sqldump/bntest_v11vJj.sql.gz" ]
    [ "$(zgrep -c 'CREATE TABLE `cache_data`' ${BN_BACKUPDIR}/mysql/sqldump/bntest_v11vJj.sql.gz)" -eq 0 ]
    [ "$(zgrep -c 'CREATE TABLE `cache_entity`' ${BN_BACKUPDIR}/mysql/sqldump/bntest_v11vJj.sql.gz)" -eq 0 ]
    [ "$(zgrep -c 'CREATE TABLE' ${BN_BACKUPDIR}/mysql/sqldump/bntest_v11vJj.sql.gz)" -eq 66 ]
}

@test "nodata: exports all databases while excluding data from one table, with compression" {
    setconfig backup.d/test.mysql databases all
    setconfig backup.d/test.mysql compress yes
    setconfig backup.d/test.mysql nodata bntest_v11vJj.cache_data
    runaction
    [ -s "${BN_BACKUPDIR}/mysql/sqldump/bntest_p8Cz8k.sql.gz" ]
    [ "$(zgrep -c 'INSERT INTO' ${BN_BACKUPDIR}/mysql/sqldump/bntest_p8Cz8k.sql.gz)" -eq 9 ]
    [ -s "${BN_BACKUPDIR}/mysql/sqldump/bntest_v11vJj.sql.gz" ]
    [ "$(zgrep -c 'INSERT INTO `cache_data`' ${BN_BACKUPDIR}/mysql/sqldump/bntest_v11vJj.sql.gz)" -eq 0 ]
    [ "$(zgrep -c 'CREATE TABLE' ${BN_BACKUPDIR}/mysql/sqldump/bntest_v11vJj.sql.gz)" -eq 68 ]
}

@test "nodata: exports all databases while excluding data from one table, without compression" {
    setconfig backup.d/test.mysql databases all
    setconfig backup.d/test.mysql compress no
    setconfig backup.d/test.mysql nodata bntest_v11vJj.cache_data
    runaction
    [ -s "${BN_BACKUPDIR}/mysql/sqldump/bntest_p8Cz8k.sql" ]
    [ "$(grep -c 'INSERT INTO' ${BN_BACKUPDIR}/mysql/sqldump/bntest_p8Cz8k.sql)" -eq 9 ]
    [ -s "${BN_BACKUPDIR}/mysql/sqldump/bntest_v11vJj.sql" ]
    [ "$(grep -c 'INSERT INTO `cache_data`' ${BN_BACKUPDIR}/mysql/sqldump/bntest_v11vJj.sql)" -eq 0 ]
    [ "$(grep -c 'CREATE TABLE' ${BN_BACKUPDIR}/mysql/sqldump/bntest_v11vJj.sql)" -eq 68 ]
}

@test "nodata: exports all databases while excluding data from two tables, with compression" {
    setconfig backup.d/test.mysql databases all
    setconfig backup.d/test.mysql compress yes
    setconfig backup.d/test.mysql nodata "bntest_v11vJj.cache_data bntest_v11vJj.cache_entity"
    runaction
    [ -s "${BN_BACKUPDIR}/mysql/sqldump/bntest_p8Cz8k.sql.gz" ]
    [ "$(zgrep -c 'INSERT INTO' ${BN_BACKUPDIR}/mysql/sqldump/bntest_p8Cz8k.sql.gz)" -eq 9 ]
    [ -s "${BN_BACKUPDIR}/mysql/sqldump/bntest_v11vJj.sql.gz" ]
    [ "$(zgrep -c 'INSERT INTO `cache_data`' ${BN_BACKUPDIR}/mysql/sqldump/bntest_v11vJj.sql.gz)" -eq 0 ]
    [ "$(zgrep -c 'INSERT INTO `cache_entity`' ${BN_BACKUPDIR}/mysql/sqldump/bntest_v11vJj.sql.gz)" -eq 0 ]
    [ "$(zgrep -c 'CREATE TABLE' ${BN_BACKUPDIR}/mysql/sqldump/bntest_v11vJj.sql.gz)" -eq 68 ]
}

@test "nodata: exports all databases while excluding data from two tables, without compression" {
    setconfig backup.d/test.mysql databases all
    setconfig backup.d/test.mysql compress no
    setconfig backup.d/test.mysql nodata "bntest_v11vJj.cache_data bntest_v11vJj.cache_entity"
    runaction
    [ -s "${BN_BACKUPDIR}/mysql/sqldump/bntest_p8Cz8k.sql" ]
    [ "$(grep -c 'INSERT INTO' ${BN_BACKUPDIR}/mysql/sqldump/bntest_p8Cz8k.sql)" -eq 9 ]
    [ -s "${BN_BACKUPDIR}/mysql/sqldump/bntest_v11vJj.sql" ]
    [ "$(grep -c 'INSERT INTO `cache_data`' ${BN_BACKUPDIR}/mysql/sqldump/bntest_v11vJj.sql)" -eq 0 ]
    [ "$(grep -c 'INSERT INTO `cache_entity`' ${BN_BACKUPDIR}/mysql/sqldump/bntest_v11vJj.sql)" -eq 0 ]
    [ "$(grep -c 'CREATE TABLE' ${BN_BACKUPDIR}/mysql/sqldump/bntest_v11vJj.sql)" -eq 68 ]
}

@test "hotcopy: exports all databases" {
    skip "not implemented, requires MyISAM tables, method is deprecated upstream"
}

@test "hotcopy: exports specific databases" {
    skip "not implemented, requires MyISAM tables, method is deprecated upstream"
}
