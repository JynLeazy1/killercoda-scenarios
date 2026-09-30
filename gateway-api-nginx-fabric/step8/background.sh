#!/bin/bash
# Escenario roto: un equipo de otro namespace intenta publicar su servicio.
cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: bakery
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bread
  namespace: bakery
spec:
  replicas: 1
  selector:
    matchLabels: {app: bread}
  template:
    metadata:
      labels: {app: bread}
    spec:
      containers:
      - name: echo
        image: registry.k8s.io/gateway-api/echo-basic:v1.5.1
        ports: [{containerPort: 3000}]
        env:
        - {name: POD_NAME, valueFrom: {fieldRef: {fieldPath: metadata.name}}}
        - {name: NAMESPACE, valueFrom: {fieldRef: {fieldPath: metadata.namespace}}}
---
apiVersion: v1
kind: Service
metadata:
  name: bread
  namespace: bakery
spec:
  selector: {app: bread}
  ports: [{port: 8080, targetPort: 3000}]
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: bakery
  namespace: cafe
spec:
  parentRefs:
  - name: cafe-gw
    namespace: infra
    sectionName: http
  hostnames:
  - bakery.example
  rules:
  - backendRefs:
    - name: bread-svc
      namespace: bakery
      port: 80
YAML
