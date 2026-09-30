# HTTPRoute and cross-namespace allowedRoutes

The application team (namespace `cafe`) creates its routes pointing at the Gateway in `infra`
through `parentRefs`. We'll create **two independent routes** for the same host.

```bash
cat <<'YAML' | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: coffee
  namespace: cafe
spec:
  parentRefs:
  - name: cafe-gw
    namespace: infra
  hostnames:
  - cafe.example
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /coffee
    backendRefs:
    - name: coffee-v1
      port: 80
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: tea
  namespace: cafe
spec:
  parentRefs:
  - name: cafe-gw
    namespace: infra
  hostnames:
  - cafe.example
  rules:
  - matches:
    - path:
        type: Exact
        value: /tea
    backendRefs:
    - name: tea
      port: 80
YAML
```{{exec}}

### Does it work?

```bash
curl -s -o /dev/null -w "%{http_code}\n" -H "Host: cafe.example" http://$NODE_IP:30080/coffee
```{{exec}}

Still `404`. Check the route's **status**: that's where the controller tells you what's going on.

```bash
kubectl get httproute coffee -n cafe -o jsonpath='{range .status.parents[*].conditions[*]}{.type}={.status} ({.reason}){"\n"}{end}'
```{{exec}}

You'll see `Accepted=False (NotAllowedByListeners)`: the listener only admits namespaces with the
label `shared-gateway-access=true`.

### Task

Add the label to the `cafe` namespace so the Gateway accepts its routes.

<details>
<summary>Solution</summary>

```bash
kubectl label namespace cafe shared-gateway-access=true
```{{exec}}

</details>

Check again (the controller may take a few seconds to reconcile and reload NGINX;
if you get a `404`, run the command again):

```bash
kubectl get httproute -n cafe
curl -s -H "Host: cafe.example" http://$NODE_IP:30080/coffee | grep -E '"(path|pod)"'
curl -s -H "Host: cafe.example" http://$NODE_IP:30080/tea | grep -E '"(path|pod)"'
curl -s -o /dev/null -w "/tea/extra -> %{http_code}\n" -H "Host: cafe.example" http://$NODE_IP:30080/tea/extra
```{{exec}}

> **Path match types:** `PathPrefix` (segment-based: `/coffee` matches `/coffee/latte` but
> **not** `/coffeeshop`), `Exact` and `RegularExpression` (implementation-specific support).
