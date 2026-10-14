# Migrate an Ingress to Gateway API

There's a legacy Ingress in `apps` (with no controller serving it):

```bash
kubectl get ingress shop -n apps -o yaml | sed -n '/^spec:/,$p'
```{{exec}}

### Equivalences

| Ingress | Gateway API |
|---|---|
| `ingressClassName` | `Gateway.spec.gatewayClassName` + `HTTPRoute.spec.parentRefs` |
| `rules[].host` | `HTTPRoute.spec.hostnames` |
| `pathType: Prefix` | `path.type: PathPrefix` |
| `pathType: Exact` | `path.type: Exact` |
| `backend.service.name/port.number` | `backendRefs[].name/port` |
| `tls[].secretName` | `Gateway.spec.listeners[].tls.certificateRefs` |
| Annotations (`rewrite-target`, `ssl-redirect`, `canary`...) | Standard filters (`URLRewrite`, `RequestRedirect`, `weight`) or implementation policies |

### Option A: generate a draft with `ingress2gateway`

SIG-Network's official tool translates Ingress (and many annotations) into Gateway API resources:

```bash
curl -sL https://github.com/kubernetes-sigs/ingress2gateway/releases/download/v1.2.0/ingress2gateway_Linux_x86_64.tar.gz | tar xz -C /usr/local/bin ingress2gateway
ingress2gateway print --providers ingress-nginx --namespace apps
```{{exec}}

It generates its own `Gateway` and an `HTTPRoute`. We already have the `eg` Gateway, so we only
need the route, with its `parentRefs` changed.

### Task

Create an `HTTPRoute` named `shop` in `apps`, attached to the `eg` Gateway, that replicates the
Ingress: `shop.example/api` → `api` and `shop.example/` → `web`.

<details>
<summary>Solution</summary>

```bash
cat <<'YAML' | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: shop
  namespace: apps
spec:
  parentRefs:
  - name: eg
  hostnames:
  - shop.example
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /api
    backendRefs:
    - name: api
      port: 80
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: web
      port: 80
YAML
```{{exec}}

</details>

```bash
curl -s -H "Host: shop.example" http://$NODE_IP:$GW_PORT/api/products | grep -E '"(path|pod)"'
curl -s -H "Host: shop.example" http://$NODE_IP:$GW_PORT/cart | grep -E '"(path|pod)"'
```{{exec}}

Once the route is validated, the Ingress is no longer needed:

```bash
kubectl delete ingress shop -n apps
```{{exec}}

> **Real-world migration strategy:** run both controllers side by side, create the `HTTPRoute`s,
> validate against the new Gateway's IP, move DNS and, finally, delete the `Ingress` objects.
