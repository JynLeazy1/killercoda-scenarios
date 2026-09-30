# Primer Gateway y HTTPRoute

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

A diferencia de NGF, Envoy Gateway crea el data plane en **su propio namespace**
(`envoy-gateway-system`) y lo etiqueta con el Gateway que lo originó:

```bash
kubectl get deploy,svc -n envoy-gateway-system -l gateway.envoyproxy.io/owning-gateway-name=eg
```{{exec}}

Guarda la IP del nodo y el NodePort asignado al puerto 80:

```bash
export NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
export GW_PORT=$(kubectl get svc -n envoy-gateway-system \
  -l gateway.envoyproxy.io/owning-gateway-name=eg,gateway.envoyproxy.io/owning-gateway-namespace=apps \
  -o jsonpath='{.items[0].spec.ports[?(@.port==80)].nodePort}')
echo "export NODE_IP=$NODE_IP GW_PORT=$GW_PORT" >> ~/.bashrc
echo "Gateway en http://$NODE_IP:$GW_PORT"
```{{exec}}

### Tarea: HTTPRoute

Crea una `HTTPRoute` llamada `web` en `apps` que envíe todo el tráfico de `www.example` al Service
`web` (puerto 80).

<details>
<summary>Solución</summary>

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

> Sin `matches`, la regla equivale a `PathPrefix /`. Sin `namespace` en `parentRefs`, se asume el
> de la ruta.

</details>

```bash
curl -s -H "Host: www.example" http://$NODE_IP:$GW_PORT/ | grep -E '"(host|pod)"'
curl -s -o /dev/null -w "otro host -> %{http_code}\n" -H "Host: otro.example" http://$NODE_IP:$GW_PORT/
```{{exec}}
