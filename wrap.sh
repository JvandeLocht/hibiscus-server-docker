#!/bin/bash

set -e


cat > /etc/hosts <<EOF
127.0.0.1 hostname localhost #hier anpassen, wenn interner DNS einen hostname hat, der dem container nicht bekannt ist.
EOF


# See for instructions:
# http://www.willuhn.de/products/hibiscus-server/install.php

dbconfig=/hibiscus-server/cfg/de.willuhn.jameica.hbci.rmi.HBCIDBService.properties

case "$DB_DRIVER" in

# Be sure to escape a ':' in DB_ADDR
mysql)
    echo "Configuring MySQL db connection to $DB_ADDR"
    cat > $dbconfig <<EOF
database.driver.mysql.jdbcdriver=com.mysql.jdbc.Driver
database.driver.mysql.jdbcurl=jdbc\:mysql\://${DB_ADDR}\:$DB_PORT/${DB_NAME}?useUnicode\=Yes&characterEncoding\=ISO8859_1
database.driver.mysql.username=${DB_USERNAME}
database.driver.mysql.password=${DB_PASSWORD}
EOF
    ;;

postgres)
    echo "Configuring PostgreSQL db connection to $DB_ADDR"
    cat > $dbconfig <<EOF
database.driver=de.willuhn.jameica.hbci.server.DBSupportPostgreSQLImpl
database.driver.postgresql.jdbcurl=jdbc\:postgresql\://${DB_ADDR/:/\\:}/${DB_NAME}
database.driver.postgresql.username=${DB_USERNAME}
database.driver.postgresql.password=${DB_PASSWORD}
EOF
    ;;

*)
    echo "Configuring local embedded database"
    # We'll delete the mysql config for now to use the embedded db
    rm $dbconfig
    ;;

esac


# Write HTTP settings
# ssl_val=false
# if [ "$USE_SSL" != "" ]; then
#     ssl_val=true
# fi
cat > /hibiscus-server/cfg/de.willuhn.jameica.webadmin.Plugin.properties <<EOF
listener.http.address=0.0.0.0
listener.http.port=${PORT:-8080}
listener.http.auth=${SHOW_BASIC_AUTH_WEBADMIN:-true}
listener.http.ssl=${USE_SSL:-true}
EOF


function initdb() {
    IFS=':' read -ra ADDR <<< "$DB_ADDR"
    DB_HOST=${ADDR[0]}
    DB_PORT=${ADDR[1]}

    case "$DB_DRIVER" in
        postgres)
            cmd="psql -h $DB_HOST -p $DB_PORT -U $DB_USERNAME  < /hibiscus-server/plugins/hibiscus/sql/postgresql-create.sql"
            echo $cmd
            eval PGPASSWORD=$DB_PASSWORD $cmd
            ;;

        mysql)
            cmd="mysql --user=$DB_USERNAME -p$DB_PASSWORD -h $DB_HOST hibiscus < /hibiscus-server/plugins/hibiscus/sql/mysql-create.sql"
            echo $cmd
            eval $cmd
            ;;
        *)
            echo "Don't know how to initialize database for driver $DB_DRIVER"
            ;;
    esac
}

if [ "$*" == "initdb" ]; then
        initdb
        exit
fi

# Write configuration file based on desired database driver
${@-/hibiscus-server/jameicaserver.sh -p $PASSWORD -f /srv/hibiscus}
