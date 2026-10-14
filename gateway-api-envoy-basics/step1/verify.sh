#!/bin/bash
kubectl -n envoy-gateway-system rollout status deployment/envoy-gateway --timeout=5s >/dev/null 2>&1 || exit 1
[ "$(kubectl get envoyproxy nodeport-proxy -n envoy-gateway-system -o jsonpath='{.spec.provider.kubernetes.envoyService.type}')" = "NodePort" ] || exit 1
[ "$(kubectl get gatewayclass eg -o jsonpath='{.spec.parametersRef.name}')" = "nodeport-proxy" ] || exit 1
[ "$(kubectl get gatewayclass eg -o jsonpath='{.status.conditions[?(@.type=="Accepted")].status}')" = "True" ] || exit 1
