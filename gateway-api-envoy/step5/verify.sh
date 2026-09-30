#!/bin/bash
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
GW_PORT=$(kubectl get svc -n envoy-gateway-system -l gateway.envoyproxy.io/owning-gateway-name=eg,gateway.envoyproxy.io/owning-gateway-namespace=apps -o jsonpath='{.items[0].spec.ports[?(@.port==80)].nodePort}')
[ "$(kubectl get httproute web -n apps -o jsonpath='{.spec.rules[0].timeouts.request}')" = "2s" ] || exit 1
[ "$(kubectl get btp web-policy -n apps -o jsonpath='{.spec.retry.numRetries}')" = "3" ] || exit 1
[ "$(kubectl get btp web-policy -n apps -o jsonpath='{.spec.rateLimit.local.rules[0].limit.requests}')" = "5" ] || exit 1
CODES=""
for i in $(seq 1 7); do CODES="$CODES $(curl -s -o /dev/null -w '%{http_code}' -H 'Host: www.example' http://$NODE_IP:$GW_PORT/)"; done
echo "$CODES" | grep -q 429 || exit 1
