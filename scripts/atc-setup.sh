#!/bin/bash
apt update && apt install -y libjson-perl
CWD=$(realpath $(dirname $0))
$CWD/setup-traffic-stats-databases.pl

influx apply -f $CWD/atc-tasks.yml --force yes

