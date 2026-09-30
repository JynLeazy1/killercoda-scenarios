#!/bin/bash
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
GW_PORT=$(kubectl get svc -n envoy-gateway-system -l gateway.envoyproxy.io/owning-gateway-name=eg,gateway.envoyproxy.io/owning-gateway-namespace=apps -o jsonpath='{.items[0].spec.ports[?(@.port==80)].nodePort}')
[ "$(kubectl get httproute shop -n apps -o jsonpath='{.status.parents[0].conditions[?(@.type=="Accepted")].status}')" = "True" ] || exit 1
curl -s -H "Host: shop.example" http://$NODE_IP:$GW_PORT/api/products | grep -q '"api-' || exit 1
curl -s -H "Host: shop.example" http://$NODE_IP:$GW_PORT/cart | grep -q '"web-' || exit 1
