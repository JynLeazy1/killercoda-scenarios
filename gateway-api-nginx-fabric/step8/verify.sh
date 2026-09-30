#!/bin/bash
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
[ "$(kubectl get httproute bakery -n cafe -o jsonpath='{.metadata.namespace}')" = "cafe" ] || exit 1
[ "$(kubectl get httproute bakery -n cafe -o jsonpath='{.status.parents[0].conditions[?(@.type=="ResolvedRefs")].status}')" = "True" ] || exit 1
kubectl get referencegrant -n bakery -o name | grep -q . || exit 1
curl -s -H "Host: bakery.example" http://$NODE_IP:30080/ | grep -q '"bread-' || exit 1
