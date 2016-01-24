#!/usr/bin/env sh

CONSUL_CONFIG=/usr/local/consul-template/consul-template.conf

sed -i -- 's/$CONSUL_URI/'$CONSUL_URI'/g' $CONSUL_CONFIG
consul-template -config $CONSUL_CONFIG &

nginx
