#!/bin/bash

set -e

CUR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $CUR/../_utils/test_prepare
WORK_DIR=$OUT_DIR/$TEST_NAME
CDC_BINARY=cdc.test

function prepare() {
    rm -rf $WORK_DIR && mkdir -p $WORK_DIR
    stop_tidb_cluster

    start_tidb_cluster $WORK_DIR

    cd $WORK_DIR

    # record tso before we create tables to skip the system table DDLs
    start_ts=$(cdc cli tso query --pd=http://$UP_PD_HOST:$UP_PD_PORT)

    run_cdc_server $WORK_DIR $CDC_BINARY
    cdc cli changefeed create --start-ts=$start_ts --sink-uri="mysql://root@127.0.0.1:3306/"
}

trap stop_tidb_cluster EXIT
prepare $*

cd "$(dirname "$0")"
set -o pipefail
GO111MODULE=on go run cdc.go -config ./config.toml 2>&1 | tee $WORK_DIR/tester.log
cleanup_process $CDC_BINARY
echo "[$(date)] <<<<<< run test case $TEST_NAME success! >>>>>>"
