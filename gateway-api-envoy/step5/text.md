# BackendTrafficPolicy: rate limit, timeouts y retries

## 1. Timeouts (estándar de Gateway API)

`HTTPRoute` soporta `timeouts` por regla sin CRDs adicionales. El backend de prueba acepta
`?delay=<duración>` para simular lentitud.

### Tarea

Configura en la ruta `web` un timeout de petición de **2s**.

<details>
<summary>Solución</summary>

```bash
kubectl patch httproute web -n apps --type=json \
  -p '[{"op":"add","path":"/spec/rules/0/timeouts","value":{"request":"2s"}}]'
```{{exec}}

</details>

```bash
curl -s -o /dev/null -w "delay=1s -> %{http_code} en %{time_total}s\n" -H "Host: www.example" "http://$NODE_IP:$GW_PORT/?delay=1s"
curl -s -o /dev/null -w "delay=5s -> %{http_code} en %{time_total}s\n" -H "Host: www.example" "http://$NODE_IP:$GW_PORT/?delay=5s"
```{{exec}}

La segunda devuelve **504** a los ~2 segundos.

## 2. Retries con `BackendTrafficPolicy`

`BackendTrafficPolicy` es una política de Envoy Gateway que se adjunta a un `Gateway` o a una ruta
mediante `targetRefs`. Con `?delay=abc` el backend responde **500**; vamos a reintentarlo.

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

Una sola petición del cliente... ¿cuántas llegan al backend?

```bash
curl -s -o /dev/null -w "%{http_code}\n" -H "Host: www.example" "http://$NODE_IP:$GW_PORT/retry-test?delay=abc"
kubectl logs -n apps deploy/web | grep -c retry-test
```{{exec}}

Deberías ver **4** (1 intento + 3 reintentos).

## 3. Rate limiting local

### Tarea

Amplía `web-policy` para limitar la ruta a **5 peticiones por minuto** (rate limit *local*, es
decir, por réplica de Envoy, sin servicio externo).

<details>
<summary>Solución</summary>

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

A partir de la sexta petición obtendrás **429** y los headers `x-ratelimit-*`.

> Con `clientSelectors` puedes limitar por header o IP de origen, y con `type: Global` compartir el
> contador entre réplicas usando un servicio de rate limit con Redis.
