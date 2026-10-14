#!/bin/bash
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
GW_PORT=$(kubectl get svc -n envoy-gateway-system -l gateway.envoyproxy.io/owning-gateway-name=eg,gateway.envoyproxy.io/owning-gateway-namespace=apps -o jsonpath='{.items[0].spec.ports[?(@.port==80)].nodePort}')
[ "$(curl -s -o /dev/null -w '%{http_code}' -H 'Host: shop.example' http://$NODE_IP:$GW_PORT/)" = "401" ] || exit 1
[ "$(curl -s -o /dev/null -w '%{http_code}' -u admin:gateway123 -H 'Host: shop.example' http://$NODE_IP:$GW_PORT/)" = "200" ] || exit 1
