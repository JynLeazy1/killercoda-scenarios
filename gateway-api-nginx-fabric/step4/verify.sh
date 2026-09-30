#!/bin/bash
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
# El header x-version: v2 siempre llega a v2
for i in 1 2 3 4 5; do
  curl -s -H "Host: cafe.example" -H "x-version: v2" http://$NODE_IP:30080/coffee | grep -q coffee-v2 || exit 1
done
# Existen pesos 80/20 en la ruta
W=$(kubectl get httproute coffee -n cafe -o jsonpath='{range .spec.rules[*].backendRefs[*]}{.name}:{.weight} {end}')
echo "$W" | grep -q 'coffee-v1:80' || exit 1
echo "$W" | grep -q 'coffee-v2:20' || exit 1
