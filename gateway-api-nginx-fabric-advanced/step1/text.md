# Filters: headers, rewrite and redirect

First, load the node IP into your shell (the setup saved it in `~/.bashrc`) and check that the
routes from Part 1 respond:

```bash
source ~/.bashrc
curl -s -H "Host: cafe.example" http://$NODE_IP:30080/tea | grep -E '"(path|pod)"'
```{{exec}}

**Filters** modify the request or the response within a rule. The standard-channel filters are:

| Filter | What it does |
|---|---|
| `RequestHeaderModifier` | Adds (`add`), overwrites (`set`) or removes (`remove`) request headers |
| `ResponseHeaderModifier` | Same, on the response |
| `URLRewrite` | Rewrites the host and/or path before forwarding to the backend |
| `RequestRedirect` | Responds with a 3xx (change of scheme, host, port or path) |
| `RequestMirror` | Copies traffic to another backend (you'll see it in the Envoy scenario) |

### Task

Rewrite the `tea` route so it has **three rules**:

1. `Exact /tea` → service `tea`, adding the request header `X-Cafe-Tier: premium` and the
   response header `X-Served-By: nginx-gateway-fabric`.
2. `PathPrefix /menu` → service `tea`, rewriting the prefix to `/tea/menu`.
3. `PathPrefix /old-tea` → **301** redirect to `/tea`.

<details>
<summary>Solution</summary>

```bash
cat <<'YAML' | kubectl apply -f -
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
    filters:
    - type: RequestHeaderModifier
      requestHeaderModifier:
        add:
        - name: X-Cafe-Tier
          value: premium
    - type: ResponseHeaderModifier
      responseHeaderModifier:
        set:
        - name: X-Served-By
          value: nginx-gateway-fabric
    backendRefs:
    - name: tea
      port: 80
  - matches:
    - path:
        type: PathPrefix
        value: /menu
    filters:
    - type: URLRewrite
      urlRewrite:
        path:
          type: ReplacePrefixMatch
          replacePrefixMatch: /tea/menu
    backendRefs:
    - name: tea
      port: 80
  - matches:
    - path:
        type: PathPrefix
        value: /old-tea
    filters:
    - type: RequestRedirect
      requestRedirect:
        path:
          type: ReplaceFullPath
          replaceFullPath: /tea
        statusCode: 301
YAML
```{{exec}}

</details>

### Try it

> After every change, NGF regenerates its configuration and reloads NGINX. If a test fails right
> after applying, wait a couple of seconds and run it again.

The backend receives the added header and we see the response header:

```bash
curl -si -H "Host: cafe.example" http://$NODE_IP:30080/tea | grep -iE 'x-served-by|x-cafe-tier' -A1
```{{exec}}

The backend receives the rewritten path:

```bash
curl -s -H "Host: cafe.example" http://$NODE_IP:30080/menu/today | grep '"path"'
```{{exec}}

The redirect:

```bash
curl -si -H "Host: cafe.example" http://$NODE_IP:30080/old-tea | grep -iE '^(HTTP|location)'
```{{exec}}

> `RequestRedirect` and `backendRefs` are incompatible in the same rule: a redirect answers the
> client directly without reaching any backend. You also can't combine `URLRewrite` with
> `RequestRedirect` in the same rule.
