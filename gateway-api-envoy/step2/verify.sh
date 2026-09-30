#!/bin/bash
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
GW_PORT=$(kubectl get svc -n envoy-gateway-system -l gateway.envoyproxy.io/owning-gateway-name=eg,gateway.envoyproxy.io/owning-gateway-namespace=apps -o jsonpath='{.items[0].spec.ports[?(@.port==80)].nodePort}')
[ -n "$GW_PORT" ] || exit 1
[ "$(kubectl get gateway eg -n apps -o jsonpath='{.status.conditions[?(@.type=="Programmed")].status}')" = "True" ] || exit 1
curl -s -H "Host: www.example" http://$NODE_IP:$GW_PORT/ | grep -q '"web-' || exit 1
