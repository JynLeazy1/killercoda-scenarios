#!/bin/bash
# Configuración rota que el alumno debe diagnosticar
cat <<'YAML' | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: status
  namespace: apps
spec:
  parentRefs:
  - name: envoy-gw
  hostnames:
  - status.example
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: web
      port: 80
---
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: BackendTrafficPolicy
metadata:
  name: status-timeouts
  namespace: apps
spec:
  targetRefs:
  - group: gateway.networking.k8s.io
    kind: HTTPRoute
    name: status-page
  timeout:
    http:
      requestTimeout: 10s
YAML
curl -sL https://github.com/envoyproxy/gateway/releases/download/v1.9.2/egctl_v1.9.2_linux_amd64.tar.gz | tar xz -C /tmp \
  && install /tmp/bin/linux/amd64/egctl /usr/local/bin/egctl
