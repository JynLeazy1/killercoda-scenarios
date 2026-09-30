#!/bin/bash
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
kubectl get ratelimitpolicy -n cafe -o jsonpath='{range .items[*].spec.targetRefs[*]}{.kind}/{.name} {end}' | grep -q 'HTTPRoute/tea' || exit 1
CODES=""
for i in $(seq 1 12); do
  CODES="$CODES $(curl -sk -o /dev/null -w '%{http_code}' --resolve cafe.example:30443:$NODE_IP https://cafe.example:30443/tea)"
done
echo "$CODES" | grep -q 429 || exit 1
