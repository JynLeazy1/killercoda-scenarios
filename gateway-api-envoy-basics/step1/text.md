# Install Envoy Gateway

Each release's `install.yaml` includes **the Gateway API CRDs** (experimental channel), the
**Envoy Gateway CRDs** and the controller. Because of its size it is applied with `--server-side`:

```bash
kubectl apply --server-side -f https://github.com/envoyproxy/gateway/releases/download/v1.9.2/install.yaml
kubectl wait --timeout=5m -n envoy-gateway-system deployment/envoy-gateway --for=condition=Available
```{{exec}}

> In production you'd typically use Helm:
> `helm install eg oci://docker.io/envoyproxy/gateway-helm --version v1.9.2 -n envoy-gateway-system --create-namespace`

Look at Envoy Gateway's own CRDs:

```bash
kubectl api-resources --api-group=gateway.envoyproxy.io
```{{exec}}

| CRD | Purpose |
|---|---|
| `EnvoyProxy` | How the data plane is deployed (replicas, Service type, resources, logs...) |
| `ClientTrafficPolicy` | Behavior between client and Envoy (timeouts, HTTP/3, real client IP...) |
| `BackendTrafficPolicy` | Between Envoy and the backend (rate limit, retries, circuit breaking, LB...) |
| `SecurityPolicy` | Authentication and authorization (Basic, JWT, OIDC, API Key, CORS...) |
| `EnvoyExtensionPolicy` | Extensions (Wasm, ext_proc, Lua) |
| `EnvoyPatchPolicy` | Low-level xDS patches |

### Task: GatewayClass with parameters

By default Envoy Gateway creates `LoadBalancer` Services. This lab has no load balancer, so create:

1. An `EnvoyProxy` named `nodeport-proxy` in `envoy-gateway-system` with a `NodePort` Service.
2. A `GatewayClass` named `eg` with controller `gateway.envoyproxy.io/gatewayclass-controller`
   that references it in `parametersRef`.

<details>
<summary>Solution</summary>

```bash
cat <<'YAML' | kubectl apply -f -
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: EnvoyProxy
metadata:
  name: nodeport-proxy
  namespace: envoy-gateway-system
spec:
  provider:
    type: Kubernetes
    kubernetes:
      envoyService:
        type: NodePort
---
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: eg
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
  parametersRef:
    group: gateway.envoyproxy.io
    kind: EnvoyProxy
    name: nodeport-proxy
    namespace: envoy-gateway-system
YAML
```{{exec}}

</details>

```bash
kubectl get gatewayclass eg
```{{exec}}

> `parametersRef` is Gateway API's **standard** mechanism for passing implementation-specific
> configuration. In NGF it points to `NginxProxy`; in Envoy Gateway, to `EnvoyProxy`.
