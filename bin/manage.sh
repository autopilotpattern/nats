#!/bin/bash

onStart() {
    logDebug "onStart"

    waitForLeader

    if [[ ! -f /etc/gnatsd.conf ]]; then
        CONSUL_HOST=${CONSUL}
        if [[ $CONSUL_AGENT -eq 1 ]]; then
          logDebug "Using consul agent"
          CONSUL_HOST="localhost"
        fi
        consul-template -consul-addr=$CONSUL_HOST:8500 -once -template=/etc/gnatsd.conf.tmpl:/etc/gnatsd.conf
        if [[ $? != 0 ]]; then
            exit 1
        fi
    fi
}

onChange() {
    logDebug "onChange"

    consul-template -consul-addr=$CONSUL_HOST:8500 -once -template=/etc/gnatsd.conf.tmpl:/etc/gnatsd.conf
    pkill -SIGHUP gnatsd
}

health() {
    logDebug "health"

    /usr/bin/curl -o /dev/null --fail -s http://127.0.0.1:8222/varz
    if [[ $? -ne 0 ]]; then
        echo "NATS monitor endpoint failed"
        exit 1
    fi
}

waitForLeader() {
    logDebug "Waiting for consul server"
    local tries=0
    while true
    do
        logDebug "Waiting for consul server"
        tries=$((tries + 1))
        local server=$(consul members -status alive | grep server)
        if [[ -n "$server" ]]; then
            break
        elif [[ $tries -eq 60 ]]; then
            echo "No consul server"
            exit 1
        fi
        sleep 1
    done
}

logDebug() {
    if [[ "${LOG_LEVEL}" == "DEBUG" ]]; then
        echo "manage: $*"
    fi
}

help() {
    echo "Usage: ./manage.sh onStart        => first-run configuration"
    echo "       ./manage.sh onChange       => reload configuration"
    echo "       ./manage.sh health         => health check NATS"
}

until
    cmd=$1
    if [[ -z "$cmd" ]]; then
        help
    fi
    shift 1
    $cmd "$@"
    [ "$?" -ne 127 ]
do
    help
    exit
done
