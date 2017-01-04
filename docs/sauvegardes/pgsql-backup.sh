#!/bin/bash

BKPDIR="/var/backups/pgsql/"
TODAY=`date +%F`
DAY=`date +%d`
MONTH=`date +%B |tr 'A-Z' 'a-z'`
DEBUG="/bin/false" #DEBUG="/bin/echo"
TMPDIR=`mktemp -d -p $BKPDIR`

echo "Log de débug cron" &> /usr/local/bin/pgbackup.log

$DEBUG "*** Start PostgreSQL databases server backup ***"
$DEBUG "dumping account objects"
export PGPASSWORD=my_pg_user_pass; nice -n 0 pg_dumpall -h localhost -U myuserpg -i --globals-only > $TMPDIR/ACCOUNT-OBJECTS.$TODAY.dump
$DEBUG "--"

for i in `psql -h localhost -U myuserpg -c "select datname from pg_database where datname <> 'template0' AND datname <> 'templategis'" -t template1`
    do
        $DEBUG "dumping database $i"
        if [ $i == "geonaturedb" ]; then
            echo "geonaturedb" &>> /usr/local/bin/pgbackup.log
            if [ $DAY == "01" ]; then
                echo "$DAY == 01" &>> /usr/local/bin/pgbackup.log
                export PGPASSWORD=my_pg_user_pass; nice -n 0 pg_dump -h localhost -U myuserpg  -i $i  > $TMPDIR/$i.$TODAY.dump
            else
                echo $DAY &>> /usr/local/bin/pgbackup.log
                export PGPASSWORD=my_pg_user_pass; nice -n 0 pg_dump -h localhost -U myuserpg -i -n public -n bryophytes -n taxonomie -n meta -n synthese -n contactflore -n florestation -n florepatri -n contactfaune -n synthese -n contactinv -n utilisateurs -i --format=t $i > $TMPDIR/$i.$TODAY.dump
            fi
        elif [ $i == "usershubdb" ]; then
            echo "usershubdb" &>> /usr/local/bin/pgbackup.log
            if [ $DAY == "01" ]; then
                echo "$DAY == 01" &>> /usr/local/bin/pgbackup.log
                export PGPASSWORD=my_pg_user_pass; nice -n 0 pg_dump -h localhost -U myuserpg -i $i  > $TMPDIR/$i.$TODAY.dump
            else
                echo $DAY &>> /usr/local/bin/pgbackup.log
                export PGPASSWORD=my_pg_user_pass; nice -n 0 pg_dump -h localhost -U myuserpg -i -n utilisateurs -i --format=t $i > $TMPDIR/$i.$TODAY.dump
            fi
        else
            echo "autres_bases" &>> /usr/local/bin/pgbackup.log
            export PGPASSWORD=my_pg_user_pass; nice -n 0 pg_dump -h localhost -U myuserpg -U myuserpg -i $i  > $TMPDIR/$i.$TODAY.dump
        fi
    done

$DEBUG "tar, transfert ftp and cleaning up..."
nice -n 0 tar -C $TMPDIR -cz -f $BKPDIR/pgsql_$DAY.tar.gz `ls $TMPDIR`
nice -n 0 ncftpput -u myserver_ovh.eu -p mypass myserver_backupftp_ovh.net /prod/dayly-backup/ $BKPDIR/pgsql_$DAY.tar.gz
nice -n 0 rm -fr $TMPDIR

if [ $DAY == "01" ]; then
	$DEBUG "*** month backup *****"
    nice -n 0 cp $BKPDIR/pgsql_$DAY.tar.gz $BKPDIR/pgsql_$MONTH.tar.gz
	nice -n 0 ncftpput -u myserver_ovh.eu -p mypass myserver_backupftp_ovh.net /prod/month-backup/ $BKPDIR/pgsql_$MONTH.tar.gz
fi

$DEBUG "*** End PostgreSQL backup *****"
