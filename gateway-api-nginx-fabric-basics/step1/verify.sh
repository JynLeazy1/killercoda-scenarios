#!/bin/bash
kubectl get crd httproutes.gateway.networking.k8s.io >/dev/null 2>&1 || exit 1
kubectl get crd nginxproxies.gateway.nginx.org >/dev/null 2>&1 || exit 1
kubectl -n nginx-gateway rollout status deployment/nginx-gateway --timeout=5s >/dev/null 2>&1 || exit 1
[ "$(kubectl get gatewayclass nginx -o jsonpath='{.status.conditions[?(@.type=="Accepted")].status}')" = "True" ] || exit 1
kubectl get nginxproxy nginx-gateway-proxy-config -n nginx-gateway -o jsonpath='{.spec.kubernetes.service.nodePorts[*].port}' | grep -q 30080 || exit 1
