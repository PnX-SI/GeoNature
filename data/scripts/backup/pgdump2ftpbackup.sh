#!/bin/bash

BKPDIR="/var/backups/pgsql"
TODAY=`date +%F`
DAY=`date +%d`
MONTH=`date +%B |tr 'A-Z' 'a-z'`
DEBUG="/bin/false" #DEBUG="/bin/echo"
TMPDIR=`mktemp -d -p $BKPDIR`

$DEBUG "*** Start PostgreSQL databases server backup ***"
$DEBUG "dumping account objects"
export PGPASSWORD=myPGpass; nice -n 0 pg_dumpall -h localhost -U myPGuser --globals-only > $TMPDIR/ACCOUNT-OBJECTS-DATABASES2.$TODAY.dump

$DEBUG "--"
$DEBUG "DATABASES"

for i in `psql -h localhost -U myPGuser -c "select datname from pg_database where datname <> 'template0'" -t template1`
    do
     $DEBUG "dumping database $i"
     if [ $i == "geonature2db" ]; then
        if [ $(date +%d) == "01" ]; then
            export PGPASSWORD=myPGpass; nice -n 0 pg_dump -h localhost -U myPGuser $i  > $TMPDIR/$i.$TODAY.dump
        else
            export PGPASSWORD=myPGpass; nice -n 0 pg_dump -h localhost -U myPGuser \
                -n 'gn_*' -n 'pr_*' -n 'taxonomie' -n 'utilisateurs' \
                -T 'taxonomie.import_taxref' -T 'taxonomie.taxhub_admin_log' -T 'taxonomie.taxref' -T 'taxonomie.taxref_*' -T 'taxonomie.vm_*' \
                $i > $TMPDIR/$i.$TODAY.dump
        fi
    else
        export PGPASSWORD=myPGpass; nice -n 0 pg_dump -h localhost -U myPGuser $i  > $TMPDIR/$i.$TODAY.dump
    fi
done

$DEBUG "tar, transfert ftp and cleaning up..."
nice -n 0 tar -C $TMPDIR -cz -f $BKPDIR/pgsql_$DAY.tar.gz `ls $TMPDIR`
nice -n 0 ncftpput -u myFTPuser -p myFTPpass myftp.url.fr /geonature2/dayly-backup/ $BKPDIR/pgsql_$DAY.tar.gz
nice -n 0 rm -fr $TMPDIR

if [ $(date +%d) == "01" ]; then
        $DEBUG "*** month backup *****"
        nice -n 0 cp $BKPDIR/pgsql_$DAY.tar.gz $BKPDIR/pgsql_$MONTH.tar.gz
        nice -n 0 ncftpput -u myFTPuser -p myFTPpass myftp.url.fr /geonature2/month-backup/ $BKPDIR/pgsql_$MONTH.tar.gz
        rm $BKPDIR/pgsql_$MONTH.tar.gz
fi 
rm $BKPDIR/pgsql_$DAY.tar.gz

$DEBUG "*** End PostgreSQL backup *****"
