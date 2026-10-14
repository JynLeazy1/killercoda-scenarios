#!/bin/bash
[ "$(kubectl get ns cafe -o jsonpath='{.metadata.labels.shared-gateway-access}')" = "true" ] || exit 1
for r in coffee tea; do
  [ "$(kubectl get httproute $r -n cafe -o jsonpath='{.status.parents[0].conditions[?(@.type=="Accepted")].status}')" = "True" ] || exit 1
done
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
curl -s -H "Host: cafe.example" http://$NODE_IP:30080/coffee | grep -q coffee-v1 || exit 1
curl -s -H "Host: cafe.example" http://$NODE_IP:30080/tea | grep -q '"tea-' || exit 1
