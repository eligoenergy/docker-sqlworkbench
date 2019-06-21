#!/bin/sh
set -e

SQLWB_ARGS="-configDir=$SQLWB_APP_DIR/config -profileStorage=$SQLWB_APP_DIR/config"
PROFILE=$1
shift
if [ "${PROFILE#-connection=}" != "${PROFILE}" ]; then
    SQLWB_ARGS="$SQLWB_ARGS $PROFILE"
elif [ -n "$PROFILE" ]; then
    SQLWB_ARGS="$SQLWB_ARGS -profile=$PROFILE"
fi

SCRIPT=$SQLWB_APP_DIR/sql/$1.sql
if [ -f "$SCRIPT" ]; then
    SQLWB_ARGS="$SQLWB_ARGS -script=$SCRIPT"
elif [ -n "$2" ]; then
    SQLWB_ARGS="$SQLWB_ARGS -command=\"$*\""
fi

cd $SQLWB_APP_DIR/exports
eval "/usr/local/bin/sqlwbconsole.sh $SQLWB_ARGS 2>&1"
