#!/bin/bash
[ "$(kubectl get gateway cafe-gw -n infra -o jsonpath='{.status.conditions[?(@.type=="Programmed")].status}')" = "True" ] || exit 1
[ "$(kubectl get gateway cafe-gw -n infra -o jsonpath='{.spec.listeners[0].allowedRoutes.namespaces.from}')" = "Selector" ] || exit 1
kubectl get svc cafe-gw-nginx -n infra -o jsonpath='{.spec.ports[*].nodePort}' | grep -q 30080 || exit 1
