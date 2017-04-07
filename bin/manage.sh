#!/bin/bash

consulCommand() {
    consul-cli --quiet --consul="${CONSUL}:8500" $*
}

onStart() {
    logDebug "onStart"

    waitForLeader

    if [[ ! -f /etc/gnatsd.conf ]]; then
        consul-template -consul-addr=${CONSUL}:8500 -once -template=/etc/gnatsd.conf.tmpl:/etc/gnatsd.conf
        if [[ $? != 0 ]]; then
            exit 1
        fi
    fi

    exec gnatsd -c /etc/gnatsd.conf $*
}

health() {
    logDebug "health"

    /usr/bin/curl -o /dev/null --fail -s http://localhost:8222
    if [[ $? -ne 0 ]]; then
        echo "NATS monitor endpoint failed"
        exit 1
    fi
}

waitForLeader() {
    logDebug "Waiting for consul leader"
    local tries=0
    while true
    do
        logDebug "Waiting for consul leader"
        tries=$((tries + 1))
        local leader=$(consulCommand --template="{{.}}" status leader)
        if [[ -n "$leader" ]]; then
            break
        elif [[ $tries -eq 60 ]]; then
            echo "No consul leader"
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
