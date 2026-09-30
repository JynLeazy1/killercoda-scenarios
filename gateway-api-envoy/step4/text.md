# Mirroring y traffic splitting

Vamos a sacar `api-v2` en dos fases.

## Fase 1: shadow traffic con `RequestMirror`

Envoy copia cada petición a `api-v2`, **descarta su respuesta** y solo devuelve la de `api`.
Así pruebas la nueva versión con tráfico real sin afectar a los usuarios.

### Tarea

Añade un filtro `RequestMirror` hacia `api-v2` en la regla `/api` de la ruta `shop`.

<details>
<summary>Solución</summary>

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

Envía tráfico: todas las respuestas vienen de `api`...

```bash
for i in $(seq 1 5); do curl -s -H "Host: shop.example" http://$NODE_IP:$GW_PORT/api/mirror-test | grep -oE '"api(-v2)?-[a-z0-9]+' | head -1; done
```{{exec}}

...pero `api-v2` también las recibió:

```bash
kubectl logs -n apps deploy/api-v2 | grep mirror-test | tail -5
```{{exec}}

## Fase 2: traffic split 50/50

### Tarea

Sustituye el mirror por un reparto **50 % `api` / 50 % `api-v2`** usando `weight`.

<details>
<summary>Solución</summary>

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

> `RequestMirror` admite además `percent`/`fraction` para copiar solo parte del tráfico.
