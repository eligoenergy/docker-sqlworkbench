#!/bin/sh
set -e

SQLWB_ARGS="-logfile=$SQLWB_LOG_DIR/workbench.log -configDir=$SQLWB_CONFIG_DIR -profileStorage=$SQLWB_CONFIG_DIR"

for TEMPLATE in $SQLWB_CONFIG_DIR/*.properties.in; do
    [ -f "$TEMPLATE" ] || continue
    echo '' | {
        OUTPUT=$SQLWB_CONFIG_DIR/$(basename -s.in $TEMPLATE)
        DEFAULTS=$SQLWB_CONFIG_DIR/$(basename -s.properties.in $TEMPLATE).default.env
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
if [ "$#" -gt 0 ]; then shift; fi
if [ "${PROFILE#-connection=}" != "${PROFILE}" ]; then
    SQLWB_ARGS="$SQLWB_ARGS $PROFILE"
elif [ -n "$PROFILE" ]; then
    SQLWB_ARGS="$SQLWB_ARGS -profile=$PROFILE"
fi

SCRIPT="$SQLWB_SCRIPT_DIR/$1.sql"
if [ -f "$SCRIPT" ]; then
    RUN_SCRIPT="$SQLWB_SCRIPT_DIR/run_script.sql"
    if [ -f "$RUN_SCRIPT" ]; then
        if [ -z "$DEBUG" ]; then
            SQLWB_ARGS="$SQLWB_ARGS -showTiming=false -feedback=false"
        fi
        SQLWB_ARGS="$SQLWB_ARGS -variable='docker_cmd_script_name=$1' -variable='docker_cmd_script_dir=$SQLWB_SCRIPT_DIR' -variable='docker_cmd_script_file=$SCRIPT' -script=$RUN_SCRIPT"
        RUN_PROPERTIES="$SQLWB_SCRIPT_DIR/run_script.properties"
        if [ -f "$RUN_PROPERTIES" ]; then
            SQLWB_ARGS="$SQLWB_ARGS -varfile=$RUN_PROPERTIES"
        fi
        SUCCESS_SCRIPT="$SQLWB_SCRIPT_DIR/cleanup_success.sql"
        if [ -f "$SUCCESS_SCRIPT" ]; then
            SQLWB_ARGS="$SQLWB_ARGS -cleanupSuccess=$SUCCESS_SCRIPT"
        fi
        ERROR_SCRIPT="$SQLWB_SCRIPT_DIR/cleanup_error.sql"
        if [ -f "$ERROR_SCRIPT" ]; then
            SQLWB_ARGS="$SQLWB_ARGS -cleanupError=$ERROR_SCRIPT"
        fi
    else
        SQLWB_ARGS="$SQLWB_ARGS -script=$SCRIPT"
    fi
    SCRIPT_PROPERTIES="$SQLWB_SCRIPT_DIR/$1.properties"
    if [ -f "$SCRIPT_PROPERTIES" ]; then
        SQLWB_ARGS="$SQLWB_ARGS -varfile=$SCRIPT_PROPERTIES"
    fi
elif [ -n "$2" ]; then
    SQLWB_ARGS="$SQLWB_ARGS -command=\"$*\""
fi

cd $SQLWB_EXPORT_DIR
# SQL Workbench/J consults the SHELL environment variable when using WbSysExec.
SQLWB_CMD="SHELL=/bin/bash /usr/local/bin/sqlwbconsole.sh $SQLWB_ARGS 2>&1"
[ -z "$DEBUG" ] || echo $SQLWB_CMD
eval $SQLWB_CMD
