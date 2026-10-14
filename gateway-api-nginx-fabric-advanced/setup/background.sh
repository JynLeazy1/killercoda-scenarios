#!/bin/bash
# Recreate the end state of Part 1 so the learner starts right where it left off.
NGF=v2.7.2
until kubectl get nodes >/dev/null 2>&1; do sleep 2; done

kubectl kustomize "https://github.com/nginx/nginx-gateway-fabric/config/crd/gateway-api/standard?ref=$NGF" | kubectl apply -f -
kubectl apply --server-side -f https://raw.githubusercontent.com/nginx/nginx-gateway-fabric/$NGF/deploy/crds.yaml
kubectl wait --for=condition=Established crd --all --timeout=120s
kubectl apply -f https://raw.githubusercontent.com/nginx/nginx-gateway-fabric/$NGF/deploy/nodeport/deploy.yaml
kubectl wait --timeout=5m -n nginx-gateway deployment/nginx-gateway --for=condition=Available
kubectl patch nginxproxy nginx-gateway-proxy-config -n nginx-gateway --type merge \
  -p '{"spec":{"kubernetes":{"service":{"nodePorts":[{"port":30080,"listenerPort":80},{"port":30443,"listenerPort":443}]}}}}'

kubectl apply -f /root/assets/apps.yaml
kubectl label namespace cafe shared-gateway-access=true --overwrite
kubectl wait -n cafe --for=condition=Available deployment --all --timeout=300s
kubectl apply -f /root/assets/gateway.yaml
kubectl wait -n infra gateway/cafe-gw --for=condition=Programmed --timeout=300s

NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
until curl -s -H "Host: cafe.example" http://$NODE_IP:30080/tea | grep -q '"tea-'; do sleep 2; done
touch /tmp/.setup-done
