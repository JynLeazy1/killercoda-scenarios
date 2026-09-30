# BackendTrafficPolicy: rate limit, timeouts and retries

## 1. Timeouts (Gateway API standard)

`HTTPRoute` supports per-rule `timeouts` with no extra CRDs. The test backend accepts
`?delay=<duration>` to simulate slowness.

### Task

Configure a request timeout of **2s** on the `web` route.

<details>
<summary>Solution</summary>

```bash
kubectl patch httproute web -n apps --type=json \
  -p '[{"op":"add","path":"/spec/rules/0/timeouts","value":{"request":"2s"}}]'
```{{exec}}

</details>

```bash
curl -s -o /dev/null -w "delay=1s -> %{http_code} in %{time_total}s\n" -H "Host: www.example" "http://$NODE_IP:$GW_PORT/?delay=1s"
curl -s -o /dev/null -w "delay=5s -> %{http_code} in %{time_total}s\n" -H "Host: www.example" "http://$NODE_IP:$GW_PORT/?delay=5s"
```{{exec}}

The second one returns **504** after ~2 seconds.

## 2. Retries with `BackendTrafficPolicy`

`BackendTrafficPolicy` is an Envoy Gateway policy that attaches to a `Gateway` or a route through
`targetRefs`. With `?delay=abc` the backend responds **500**; let's retry it.

```bash
cat <<'YAML' | kubectl apply -f -
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: BackendTrafficPolicy
metadata:
  name: web-policy
  namespace: apps
spec:
  targetRefs:
  - group: gateway.networking.k8s.io
    kind: HTTPRoute
    name: web
  retry:
    numRetries: 3
    retryOn:
      triggers: ["retriable-status-codes"]
      httpStatusCodes: [500]
    perRetry:
      backOff:
        baseInterval: 100ms
        maxInterval: 500ms
YAML
kubectl get backendtrafficpolicy web-policy -n apps -o jsonpath='{range .status.ancestors[*].conditions[*]}{.type}={.status}{"\n"}{end}'
```{{exec}}

A single client request... how many reach the backend?

```bash
curl -s -o /dev/null -w "%{http_code}\n" -H "Host: www.example" "http://$NODE_IP:$GW_PORT/retry-test?delay=abc"
kubectl logs -n apps deploy/web | grep -c retry-test
```{{exec}}

You should see **4** (1 attempt + 3 retries).

## 3. Local rate limiting

### Task

Extend `web-policy` to limit the route to **5 requests per minute** (a *local* rate limit, i.e.
per Envoy replica, with no external service).

<details>
<summary>Solution</summary>

```bash
kubectl patch backendtrafficpolicy web-policy -n apps --type=merge -p '
spec:
  rateLimit:
    type: Local
    local:
      rules:
      - limit:
          requests: 5
          unit: Minute
'
```{{exec}}

</details>

```bash
for i in $(seq 1 8); do curl -s -o /dev/null -w "%{http_code} " -H "Host: www.example" http://$NODE_IP:$GW_PORT/; done; echo
curl -si -H "Host: www.example" http://$NODE_IP:$GW_PORT/ | grep -i ratelimit
```{{exec}}

From the sixth request on you'll get **429** and the `x-ratelimit-*` headers.

> With `clientSelectors` you can limit per header or source IP, and with `type: Global` share the
> counter across replicas using a rate limit service backed by Redis.
