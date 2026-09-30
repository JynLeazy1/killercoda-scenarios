# Canary: weights and header matching

We want to roll out `coffee-v2` progressively:

* Anyone sending the header `x-version: v2` always reaches **v2** (internal testing).
* The rest of the traffic is split **80% v1 / 20% v2**.

### Task

Modify the `coffee` route to implement that behavior.

<details>
<summary>Solution</summary>

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
      headers:
      - name: x-version
        value: v2
    backendRefs:
    - name: coffee-v2
      port: 80
  - matches:
    - path:
        type: PathPrefix
        value: /coffee
    backendRefs:
    - name: coffee-v1
      port: 80
      weight: 80
    - name: coffee-v2
      port: 80
      weight: 20
YAML
```{{exec}}

</details>

### Test the split

```bash
for i in $(seq 1 50); do
  curl -s -H "Host: cafe.example" http://$NODE_IP:30080/coffee | grep -oE 'coffee-v[12]' | head -1
done | sort | uniq -c
```{{exec}}

And the header match:

```bash
for i in $(seq 1 5); do
  curl -s -H "Host: cafe.example" -H "x-version: v2" http://$NODE_IP:30080/coffee | grep -oE 'coffee-v[12]' | head -1
done
```{{exec}}

> **Precedence:** when several rules match, the most specific one wins (exact path before prefix,
> longer prefix, more headers, more query params...). That's why the header rule wins even though
> both use `/coffee`. A `weight: 0` disables a backend without removing it.
