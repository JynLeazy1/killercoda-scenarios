#!/bin/bash
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
kubectl get secret cafe-tls -n infra >/dev/null 2>&1 || exit 1
[ "$(kubectl get gateway cafe-gw -n infra -o jsonpath='{.spec.listeners[?(@.name=="https")].protocol}')" = "HTTPS" ] || exit 1
curl -sk --resolve cafe.example:30443:$NODE_IP https://cafe.example:30443/coffee | grep -q coffee-v || exit 1
R=$(curl -s -o /dev/null -w '%{http_code} %{redirect_url}' -H "Host: cafe.example" http://$NODE_IP:30080/coffee)
echo "$R" | grep -q '^301 https://cafe.example:30443/coffee' || exit 1
