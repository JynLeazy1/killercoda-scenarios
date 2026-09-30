#!/bin/bash
# api-v2 recibió tráfico espejado y la ruta /api reparte entre api y api-v2
kubectl logs -n apps deploy/api-v2 2>/dev/null | grep -q mirror-test || exit 1
W=$(kubectl get httproute shop -n apps -o jsonpath='{range .spec.rules[0].backendRefs[*]}{.name}:{.weight} {end}')
echo "$W" | grep -q 'api:50' || exit 1
echo "$W" | grep -q 'api-v2:50' || exit 1
