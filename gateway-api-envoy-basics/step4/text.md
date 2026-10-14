# Mirroring and traffic splitting

We'll roll out `api-v2` in two phases.

## Phase 1: shadow traffic with `RequestMirror`

Envoy copies every request to `api-v2`, **discards its response** and only returns the one from
`api`. That way you test the new version with real traffic without affecting users.

### Task

Add a `RequestMirror` filter towards `api-v2` to the `/api` rule of the `shop` route.

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
    filters:
    - type: RequestMirror
      requestMirror:
        backendRef:
          name: api-v2
          port: 80
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

Send some traffic: every response comes from `api`...

```bash
for i in $(seq 1 5); do curl -s -H "Host: shop.example" http://$NODE_IP:$GW_PORT/api/mirror-test | grep -oE '"api(-v2)?-[a-z0-9]+' | head -1; done
```{{exec}}

...but `api-v2` received them too:

```bash
kubectl logs -n apps deploy/api-v2 | grep mirror-test | tail -5
```{{exec}}

## Phase 2: 50/50 traffic split

### Task

Replace the mirror with a **50% `api` / 50% `api-v2`** split using `weight`.

<details>
<summary>Solution</summary>

```bash
kubectl patch httproute shop -n apps --type=json -p '[
  {"op":"remove","path":"/spec/rules/0/filters"},
  {"op":"replace","path":"/spec/rules/0/backendRefs","value":[
    {"name":"api","port":80,"weight":50},
    {"name":"api-v2","port":80,"weight":50}
  ]}
]'
```{{exec}}

</details>

```bash
for i in $(seq 1 40); do curl -s -H "Host: shop.example" http://$NODE_IP:$GW_PORT/api | grep -oE '"api(-v2)?-' | head -1; done | sort | uniq -c
```{{exec}}

> `RequestMirror` also supports `percent`/`fraction` to copy only part of the traffic.
