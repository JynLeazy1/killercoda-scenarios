# Rate limiting with RateLimitPolicy

Gateway API defines routing, but many capabilities (rate limiting, timeouts, body size,
keep-alive...) are exposed through **Policy Attachment**: implementation-specific CRDs that
"attach" to a Gateway or a route through `targetRefs`.

NGF policies:

```bash
kubectl api-resources --api-group=gateway.nginx.org
```{{exec}}

| Policy | Use |
|---|---|
| `ClientSettingsPolicy` | Max body size, client keep-alive |
| `ProxySettingsPolicy` | Upstream buffers |
| `UpstreamSettingsPolicy` | Keep-alive and shared memory zone towards backends |
| `RateLimitPolicy` | Request limiting (NGINX `limit_req`) |
| `ObservabilityPolicy` | Tracing (OpenTelemetry) |

### Task

Create a `RateLimitPolicy` named `tea-ratelimit` in `cafe` that limits the `tea` route to
**2 requests per second per IP** and rejects the excess with **429**.

<details>
<summary>Solution</summary>

```bash
cat <<'YAML' | kubectl apply -f -
apiVersion: gateway.nginx.org/v1alpha1
kind: RateLimitPolicy
metadata:
  name: tea-ratelimit
  namespace: cafe
spec:
  targetRefs:
  - group: gateway.networking.k8s.io
    kind: HTTPRoute
    name: tea
  rateLimit:
    rejectCode: 429
    local:
      rules:
      - key: $binary_remote_addr
        rate: 2r/s
        zoneSize: 10m
YAML
```{{exec}}

</details>

Check that the policy was accepted (policies have a `status` too):

```bash
kubectl describe rlpolicy tea-ratelimit -n cafe | sed -n '/Status:/,$p'
```{{exec}}

### Try it

```bash
for i in $(seq 1 10); do
  curl -sk -o /dev/null -w "%{http_code} " --resolve cafe.example:30443:$NODE_IP https://cafe.example:30443/tea
done; echo
```{{exec}}

You should see a few `200`s followed by `429`s. The `coffee` route is not affected:

```bash
for i in $(seq 1 10); do
  curl -sk -o /dev/null -w "%{http_code} " --resolve cafe.example:30443:$NODE_IP https://cafe.example:30443/coffee
done; echo
```{{exec}}

> These policies are **not portable**: if you switch implementations (e.g. to Envoy Gateway) you
> have to translate them into its equivalent CRDs. Routing (`HTTPRoute`), on the other hand, is portable.
