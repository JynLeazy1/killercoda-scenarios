#!/bin/bash
# Recreate the end state of Part 1 so the learner starts right where it left off.
EG=v1.9.2
until kubectl get nodes >/dev/null 2>&1; do sleep 2; done

kubectl apply --server-side -f https://github.com/envoyproxy/gateway/releases/download/$EG/install.yaml
kubectl wait --for=condition=Established crd --all --timeout=120s
kubectl wait --timeout=5m -n envoy-gateway-system deployment/envoy-gateway --for=condition=Available

kubectl apply -f /root/assets/apps.yaml
kubectl wait -n apps --for=condition=Available deployment --all --timeout=300s
kubectl apply -f /root/assets/gateway.yaml
kubectl wait -n apps gateway/eg --for=condition=Programmed --timeout=300s

NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
GW_PORT=$(kubectl get svc -n envoy-gateway-system \
  -l gateway.envoyproxy.io/owning-gateway-name=eg,gateway.envoyproxy.io/owning-gateway-namespace=apps \
  -o jsonpath='{.items[0].spec.ports[?(@.port==80)].nodePort}')
until curl -s -H "Host: www.example" http://$NODE_IP:$GW_PORT/ | grep -q '"web-'; do sleep 2; done
echo "export NODE_IP=$NODE_IP GW_PORT=$GW_PORT" >> /root/.bashrc
touch /tmp/.setup-done
