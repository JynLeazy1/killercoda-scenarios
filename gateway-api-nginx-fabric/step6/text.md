# TLS y redirección HTTP → HTTPS

### 1. Certificado y Secret

Genera un certificado autofirmado para `cafe.example` y guárdalo como Secret TLS **en el namespace
del Gateway** (así no hace falta `ReferenceGrant`):

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout cafe.key -out cafe.crt \
  -subj "/CN=cafe.example" -addext "subjectAltName=DNS:cafe.example"
kubectl create secret tls cafe-tls -n infra --cert=cafe.crt --key=cafe.key
```{{exec}}

### 2. Listener HTTPS

Añade un segundo listener al Gateway:

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

El Service ahora expone también `443:30443`, gracias al `NginxProxy` que configuraste en el paso 1.

### 3. `sectionName`: atar rutas a un listener concreto

Una ruta sin `sectionName` se adjunta a **todos** los listeners compatibles. Queremos que `coffee` y
`tea` solo sirvan por HTTPS:

```bash
for r in coffee tea; do
  kubectl patch httproute $r -n cafe --type=json \
    -p '[{"op":"add","path":"/spec/parentRefs/0/sectionName","value":"https"}]'
done
```{{exec}}

### 4. Tarea: redirección HTTP → HTTPS

Crea una `HTTPRoute` llamada `https-redirect` en el namespace `cafe`, adjunta **solo** al listener
`http`, para el host `cafe.example`, que responda con un **301** al esquema `https` y puerto `30443`.

<details>
<summary>Solución</summary>

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

> En producción el puerto sería 443 y podrías omitirlo; aquí usamos el NodePort.

</details>

### Pruébalo

> Tras cada cambio, NGF regenera la configuración y recarga NGINX. Si una prueba falla justo
> después de aplicar, espera un par de segundos y repítela.

`--resolve` hace que curl envíe el SNI y el Host correctos sin tocar `/etc/hosts`:

```bash
curl -si -H "Host: cafe.example" http://$NODE_IP:30080/coffee | grep -iE '^(HTTP|location)'
curl -sk --resolve cafe.example:30443:$NODE_IP https://cafe.example:30443/coffee | grep -E '"(path|pod)"'
curl -svk --resolve cafe.example:30443:$NODE_IP https://cafe.example:30443/tea -o /dev/null 2>&1 | grep -E 'subject|SSL connection'
```{{exec}}
