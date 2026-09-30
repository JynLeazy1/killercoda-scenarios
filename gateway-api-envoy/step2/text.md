# First Gateway and HTTPRoute

### Gateway

```bash
cat <<'YAML' | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: eg
  namespace: apps
spec:
  gatewayClassName: eg
  listeners:
  - name: http
    protocol: HTTP
    port: 80
YAML
kubectl wait -n apps gateway/eg --for=condition=Programmed --timeout=180s
```{{exec}}

Unlike NGF, Envoy Gateway creates the data plane in **its own namespace**
(`envoy-gateway-system`) and labels it with the Gateway it belongs to:

```bash
kubectl get deploy,svc -n envoy-gateway-system -l gateway.envoyproxy.io/owning-gateway-name=eg
```{{exec}}

Save the node IP and the NodePort assigned to port 80:

```bash
export NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
export GW_PORT=$(kubectl get svc -n envoy-gateway-system \
  -l gateway.envoyproxy.io/owning-gateway-name=eg,gateway.envoyproxy.io/owning-gateway-namespace=apps \
  -o jsonpath='{.items[0].spec.ports[?(@.port==80)].nodePort}')
echo "export NODE_IP=$NODE_IP GW_PORT=$GW_PORT" >> ~/.bashrc
echo "Gateway at http://$NODE_IP:$GW_PORT"
```{{exec}}

### Task: HTTPRoute

Create an `HTTPRoute` named `web` in `apps` that sends all traffic for `www.example` to the `web`
Service (port 80).

<details>
<summary>Solution</summary>

```bash
cat <<'YAML' | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web
  namespace: apps
spec:
  parentRefs:
  - name: eg
  hostnames:
  - www.example
  rules:
  - backendRefs:
    - name: web
      port: 80
YAML
```{{exec}}

> Without `matches`, the rule is equivalent to `PathPrefix /`. Without a `namespace` in
> `parentRefs`, the route's own namespace is assumed.

</details>

```bash
curl -s -H "Host: www.example" http://$NODE_IP:$GW_PORT/ | grep -E '"(host|pod)"'
curl -s -o /dev/null -w "other host -> %{http_code}\n" -H "Host: other.example" http://$NODE_IP:$GW_PORT/
```{{exec}}
