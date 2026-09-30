# Install Gateway API and NGINX Gateway Fabric

Gateway API is **not bundled** with Kubernetes: its resources are CRDs that you install separately.
Each implementation supports a specific version, so we use the one that ships with NGF.

### 1. Gateway API CRDs (*standard* channel)

```bash
kubectl kustomize "https://github.com/nginx/nginx-gateway-fabric/config/crd/gateway-api/standard?ref=v2.7.2" | kubectl apply -f -
```{{exec}}

Check which new types are now in the cluster:

```bash
kubectl api-resources --api-group=gateway.networking.k8s.io
```{{exec}}

> The **standard** channel contains stable resources (`GatewayClass`, `Gateway`, `HTTPRoute`,
> `GRPCRoute`, `ReferenceGrant`...). The **experimental** channel adds things like `TCPRoute` or `TLSRoute`.

### 2. NGF's own CRDs

NGF adds CRDs for its configuration and for *policies* (rate limiting, timeouts, etc.):

```bash
kubectl apply --server-side -f https://raw.githubusercontent.com/nginx/nginx-gateway-fabric/v2.7.2/deploy/crds.yaml
```{{exec}}

### 3. The controller

This lab has no external load balancer, so we use the manifest that exposes the data plane as a
`NodePort`:

```bash
kubectl apply -f https://raw.githubusercontent.com/nginx/nginx-gateway-fabric/v2.7.2/deploy/nodeport/deploy.yaml
kubectl wait --timeout=5m -n nginx-gateway deployment/nginx-gateway --for=condition=Available
```{{exec}}

### 4. Inspect the GatewayClass

```bash
kubectl get gatewayclass
kubectl describe gatewayclass nginx
```{{exec}}

It should show `ACCEPTED=True`. Note the `parametersRef`: it points to an `NginxProxy` resource,
which is where NGF keeps the data plane configuration (replicas, Service type, image...).

### 5. Pin the NodePorts

So you don't have to look up random ports, tell NGF which NodePort to use for each listener port:

```bash
kubectl patch nginxproxy nginx-gateway-proxy-config -n nginx-gateway --type merge -p '
{"spec":{"kubernetes":{"service":{"nodePorts":[
  {"port":30080,"listenerPort":80},
  {"port":30443,"listenerPort":443}
]}}}}'
```{{exec}}

> **NGF 2.x architecture:** the *control plane* (`nginx-gateway`) watches Gateway API resources and,
> for **each `Gateway`** you create, provisions an NGINX Deployment + Service (the *data plane*) in
> the Gateway's namespace. That's why you don't see any NGINX running yet.
