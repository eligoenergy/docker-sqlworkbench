#!/bin/sh
set -e

# FUNCTION: sync_dir()
# ARGUMENTS:
# $1: Source directory
# $2: destination directory
# copy any missing files from our /usr/local/share/sqlworkbench folder
# to our /app folder
sync_dir() 
{
	for f in `ls $1`
	do
	    [ -f $2/$f ] && continue;
        [ -z "$DEBUG" ] || echo "Replacing missing file ${2}/${f}"
        cp -f $1/$f $2/$f
	done
}

sync_dir $SQLWB_SHARE_DIR/config $SQLWB_APP_DIR/config
sync_dir $SQLWB_SHARE_DIR/sql $SQLWB_APP_DIR/sql

/usr/local/bin/docker-cmd.sh $@
