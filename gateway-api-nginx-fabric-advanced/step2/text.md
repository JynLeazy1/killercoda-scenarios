# TLS and HTTP → HTTPS redirect

### 1. Certificate and Secret

Generate a self-signed certificate for `cafe.example` and store it as a TLS Secret **in the
Gateway's namespace** (so no `ReferenceGrant` is needed):

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout cafe.key -out cafe.crt \
  -subj "/CN=cafe.example" -addext "subjectAltName=DNS:cafe.example"
kubectl create secret tls cafe-tls -n infra --cert=cafe.crt --key=cafe.key
```{{exec}}

### 2. HTTPS listener

Add a second listener to the Gateway:

```bash
cat <<'YAML' | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: cafe-gw
  namespace: infra
spec:
  gatewayClassName: nginx
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Selector
        selector:
          matchLabels:
            shared-gateway-access: "true"
  - name: https
    port: 443
    protocol: HTTPS
    hostname: cafe.example
    tls:
      mode: Terminate
      certificateRefs:
      - kind: Secret
        name: cafe-tls
    allowedRoutes:
      namespaces:
        from: Selector
        selector:
          matchLabels:
            shared-gateway-access: "true"
YAML
kubectl wait -n infra gateway/cafe-gw --for=condition=Programmed --timeout=60s
kubectl get svc cafe-gw-nginx -n infra
```{{exec}}

The Service now also exposes `443:30443`, thanks to the `NginxProxy` NodePort mapping configured in Part 1.

### 3. `sectionName`: bind routes to a specific listener

A route without `sectionName` attaches to **every** compatible listener. We want `coffee` and
`tea` to be served over HTTPS only:

```bash
for r in coffee tea; do
  kubectl patch httproute $r -n cafe --type=json \
    -p '[{"op":"add","path":"/spec/parentRefs/0/sectionName","value":"https"}]'
done
```{{exec}}

### 4. Task: HTTP → HTTPS redirect

Create an `HTTPRoute` named `https-redirect` in the `cafe` namespace, attached **only** to the
`http` listener, for host `cafe.example`, that responds with a **301** to scheme `https` and port `30443`.

<details>
<summary>Solution</summary>

```bash
cat <<'YAML' | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: https-redirect
  namespace: cafe
spec:
  parentRefs:
  - name: cafe-gw
    namespace: infra
    sectionName: http
  hostnames:
  - cafe.example
  rules:
  - filters:
    - type: RequestRedirect
      requestRedirect:
        scheme: https
        port: 30443
        statusCode: 301
YAML
```{{exec}}

> In production the port would be 443 and you could omit it; here we use the NodePort.

</details>

### Try it

> After every change, NGF regenerates its configuration and reloads NGINX. If a test fails right
> after applying, wait a couple of seconds and run it again.

`--resolve` makes curl send the right SNI and Host without touching `/etc/hosts`:

```bash
curl -si -H "Host: cafe.example" http://$NODE_IP:30080/coffee | grep -iE '^(HTTP|location)'
curl -sk --resolve cafe.example:30443:$NODE_IP https://cafe.example:30443/coffee | grep -E '"(path|pod)"'
curl -svk --resolve cafe.example:30443:$NODE_IP https://cafe.example:30443/tea -o /dev/null 2>&1 | grep -E 'subject|SSL connection'
```{{exec}}
