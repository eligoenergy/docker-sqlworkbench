#!/bin/sh
set -e

SQLWB_CONFIG="$SQLWB_APP_DIR/config"
SQLWB_ARGS="-configDir=$SQLWB_CONFIG -profileStorage=$SQLWB_CONFIG"

for TEMPLATE in $SQLWB_CONFIG/*.properties.in; do
    [ -f "$TEMPLATE" ] || continue
    echo '' | {
        OUTPUT=$SQLWB_CONFIG/$(basename -s.in $TEMPLATE)
        DEFAULTS=$SQLWB_CONFIG/$(basename -s.properties.in $TEMPLATE).default.env
        if [ -f "$DEFAULTS" ]; then
            DEFAULT_ENV=`env - sh -ac ". $DEFAULTS; env"`
            while IFS= read -r DEFAULT; do
                NAME=`echo $DEFAULT | sed -E 's|^(.+)=(.*)$|\1|g'`
                eval CURRENT_VALUE="\$$NAME"
                [ -z "$CURRENT_VALUE" ] || continue
                DEFAULT_VALUE=`echo $DEFAULT | sed -e "s|$NAME=||"`
                eval $NAME=$DEFAULT_VALUE; export $NAME
            done <<EOF
$DEFAULT_ENV
EOF
        fi
        envsubst < "$TEMPLATE" > "$OUTPUT"
    }
done

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
# SQL Workbench/J consults the SHELL environment variable when using WbSysExec.
eval "SHELL=/bin/bash /usr/local/bin/sqlwbconsole.sh $SQLWB_ARGS 2>&1"
