#!/bin/bash
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
OUT=$(curl -si -H "Host: cafe.example" http://$NODE_IP:30080/tea)
echo "$OUT" | grep -qi '^x-served-by: nginx-gateway-fabric' || exit 1
echo "$OUT" | grep -qi 'premium' || exit 1
curl -s -H "Host: cafe.example" http://$NODE_IP:30080/menu/today | grep '"path"' | grep -q '/tea/menu/today' || exit 1
R=$(curl -s -o /dev/null -w '%{http_code} %{redirect_url}' -H "Host: cafe.example" http://$NODE_IP:30080/old-tea)
echo "$R" | grep -q '^301 .*/tea$' || exit 1
