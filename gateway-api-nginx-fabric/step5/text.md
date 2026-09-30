# Filtros: headers, rewrite y redirect

Los **filtros** modifican la petición o la respuesta en una regla. Los del canal standard son:

| Filtro | Qué hace |
|---|---|
| `RequestHeaderModifier` | Añade (`add`), sobrescribe (`set`) o elimina (`remove`) headers de la petición |
| `ResponseHeaderModifier` | Lo mismo, sobre la respuesta |
| `URLRewrite` | Reescribe host y/o path antes de enviar al backend |
| `RequestRedirect` | Responde con un 3xx (cambio de esquema, host, puerto o path) |
| `RequestMirror` | Copia el tráfico a otro backend (lo verás en el escenario de Envoy) |

### Tarea

Reescribe la ruta `tea` para que tenga **tres reglas**:

1. `Exact /tea` → servicio `tea`, añadiendo el header de petición `X-Cafe-Tier: premium` y el
   header de respuesta `X-Served-By: nginx-gateway-fabric`.
2. `PathPrefix /menu` → servicio `tea`, reescribiendo el prefijo a `/tea/menu`.
3. `PathPrefix /old-tea` → redirección **301** a `/tea`.

<details>
<summary>Solución</summary>

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

### Pruébalo

> Tras cada cambio, NGF regenera la configuración y recarga NGINX. Si una prueba falla justo
> después de aplicar, espera un par de segundos y repítela.

El backend recibe el header añadido y nosotros vemos el de respuesta:

```bash
curl -si -H "Host: cafe.example" http://$NODE_IP:30080/tea | grep -iE 'x-served-by|x-cafe-tier' -A1
```{{exec}}

El backend recibe el path reescrito:

```bash
curl -s -H "Host: cafe.example" http://$NODE_IP:30080/menu/today | grep '"path"'
```{{exec}}

La redirección:

```bash
curl -si -H "Host: cafe.example" http://$NODE_IP:30080/old-tea | grep -iE '^(HTTP|location)'
```{{exec}}

> `RequestRedirect` y `backendRefs` son incompatibles en la misma regla: una redirección responde
> directamente al cliente sin llegar a ningún backend. Tampoco se puede combinar `URLRewrite` con
> `RequestRedirect` en la misma regla.
