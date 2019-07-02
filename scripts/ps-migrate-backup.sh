#!/bin/bash

TEMP_BAK_NAME=ps-toolkit-migrate-backup
TEMP_BAK_DIR="/tmp/$TEMP_BAK_NAME"

#Check parameters
TEMP=$(getopt -o d --long data -n $0 -- "$@")
if [ $? != 0 ]; then
    echo "Usage: $0 [-d|--data] <tgz-file>"
    echo "Unable to parse command line"
    exit 1
fi
eval set -- "$TEMP"

while true; do
   case "$1" in
       -d|--data) DATA=1 ; shift ;;
       --) shift ; break ;;
       *) echo "Internal error!" ; exit 1 ;;
   esac
done

#Check options
if [ -z "$1" ]; then
    echo "Usage: $0 [-d|--data] <tgz-file>"
    echo "Missing path to tar file in options list"
    exit 1
elif [ -e "$1" ]; then
    echo "Backup file already exists: $1"
    exit 1
fi

#Create temp directory
rm -rf $TEMP_BAK_DIR
mkdir -m 700 $TEMP_BAK_DIR
if [ "$?" != "0" ]; then
    echo "Unable to create temp directory"
    exit 1
fi

#create directory structure
mkdir -p $TEMP_BAK_DIR/etc
mkdir -p $TEMP_BAK_DIR/cassandra_data
mkdir -p $TEMP_BAK_DIR/postgresql_data

#get perfsonar files
printf "Backing-up perfsonar configuration..."
cp -a /etc/perfsonar $TEMP_BAK_DIR/etc
if [ "$?" != "0" ]; then
    echo "Unable to copy /etc/perfsonar"
    exit 1
fi
printf "[SUCCESS]"
echo ""

#get owamp files
printf "Backing-up owamp-server configuration..."
cp -a /etc/owamp-server $TEMP_BAK_DIR/etc
if [ "$?" != "0" ]; then
    echo "Unable to copy /etc/owamp-server"
    exit 1
fi
printf "[SUCCESS]"
echo ""

#get NTP config
printf "Backing-up NTP configuration..."
cp /etc/ntp.conf  $TEMP_BAK_DIR/etc/ntp.conf
if [ "$?" != "0" ]; then
    echo "Unable to copy /etc/ntp.conf"
    exit 1
fi
printf "[SUCCESS]"
echo ""

#get maddash if exists
if [ -f "/etc/maddash/maddash-server/maddash.yaml" ]; then
    printf "Backing-up MaDDash configuration..."
    cp -a /etc/maddash $TEMP_BAK_DIR/etc
    if [ "$?" != "0" ]; then
        echo "Unable to copy /etc/maddash"
        exit 1
    fi
    printf "[SUCCESS]"
    echo ""
fi

#backup databases
if [ "$DATA" ]; then
    if [ -d /var/lib/cassandra/data/esmond ]; then
        printf "Backing-up cassandra data for esmond..."
        nodetool clearsnapshot esmond -t esmond_snapshot &>/dev/null
        if ! nodetool snapshot esmond -t esmond_snapshot &>/dev/null; then
            echo "Unable to snapshot cassandra database"
            exit 1
        fi
        for SNAPSHOT in /var/lib/cassandra/data/esmond/*/snapshots/esmond_snapshot; do
            TABLE=${SNAPSHOT%/snapshots/*}
            TABLE=${TABLE#*/esmond/}
            mkdir $TEMP_BAK_DIR/cassandra_data/$TABLE
            cp -a $SNAPSHOT $TEMP_BAK_DIR/cassandra_data/$TABLE/
            if [ "$?" != "0" ]; then
                echo "Unable to copy $TABLE snapshot"
                exit 1
            fi
        done
        nodetool clearsnapshot esmond -t esmond_snapshot &>/dev/null
        printf "[SUCCESS]"
        echo ""
    fi

    PG_DUMP=pg_dump
    [ -x /usr/pgsql-9.5/bin/pg_dump ] && PG_DUMP=/usr/pgsql-9.5/bin/pg_dump

    printf "Backing-up postgresql data for esmond..."
    export PGUSER=$(sed -n -e 's/sql_db_user = //p' /etc/esmond/esmond.conf)
    export PGPASSWORD=$(sed -n -e 's/sql_db_password = //p' /etc/esmond/esmond.conf)
    export PGDATABASE=$(sed -n -e 's/sql_db_name = //p' /etc/esmond/esmond.conf)
    $PG_DUMP --no-password > $TEMP_BAK_DIR/postgresql_data/esmond.dump 2>/dev/null
    if [ "$?" != "0" ]; then
        echo "Unable to dump esmond database"
        exit 1
    fi
    unset PGUSER PGPASSWORD PGDATABASE
    printf "[SUCCESS]"
    echo ""
fi

#get pscheduler if exists
if which pscheduler > /dev/null; then
    pscheduler backup > $TEMP_BAK_DIR/pscheduler
    if [ "$?" != "0" ]; then
        echo "Unable to create pScheduler backup"
        exit 1
    fi
fi

#create tar
printf "Creating backup file..."
CUR_DIR=`pwd`
cd /tmp
tar -czf $TEMP_BAK_NAME.tgz $TEMP_BAK_NAME
if [ "$?" != "0" ]; then
    echo "Unable to create tarball"
    exit 1
fi

cd $CUR_DIR
mv /tmp/$TEMP_BAK_NAME.tgz $1
if [ "$?" != "0" ]; then
    echo "Unable to move tarball to $1"
    exit 1
fi
printf "[SUCCESS]"
echo ""

#Clean up temp directory
rm -rf $TEMP_BAK_DIR
echo "Backup complete."
