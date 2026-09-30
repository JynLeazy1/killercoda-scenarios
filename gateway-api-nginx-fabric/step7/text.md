# Rate limiting con RateLimitPolicy

Gateway API define el enrutamiento, pero muchas capacidades (rate limiting, timeouts, tamaño de
body, keep-alive...) se exponen como **Policy Attachment**: CRDs de cada implementación que se
"enganchan" a un Gateway o a una ruta mediante `targetRefs`.

Políticas de NGF:

```bash
kubectl api-resources --api-group=gateway.nginx.org
```{{exec}}

| Política | Uso |
|---|---|
| `ClientSettingsPolicy` | Tamaño máximo de body, keep-alive del cliente |
| `ProxySettingsPolicy` | Buffers hacia el upstream |
| `UpstreamSettingsPolicy` | Keep-alive y zona de memoria hacia los backends |
| `RateLimitPolicy` | Limitación de peticiones (`limit_req` de NGINX) |
| `ObservabilityPolicy` | Tracing (OpenTelemetry) |

### Tarea

Crea una `RateLimitPolicy` llamada `tea-ratelimit` en `cafe` que limite la ruta `tea` a
**2 peticiones por segundo por IP** y rechace el exceso con **429**.

<details>
<summary>Solución</summary>

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

Revisa que la política fue aceptada (las políticas también tienen `status`):

```bash
kubectl describe rlpolicy tea-ratelimit -n cafe | sed -n '/Status:/,$p'
```{{exec}}

### Pruébalo

```bash
for i in $(seq 1 10); do
  curl -sk -o /dev/null -w "%{http_code} " --resolve cafe.example:30443:$NODE_IP https://cafe.example:30443/tea
done; echo
```{{exec}}

Deberías ver algunos `200` seguidos de `429`. La ruta `coffee` no está afectada:

```bash
for i in $(seq 1 10); do
  curl -sk -o /dev/null -w "%{http_code} " --resolve cafe.example:30443:$NODE_IP https://cafe.example:30443/coffee
done; echo
```{{exec}}

> Estas políticas **no son portables**: si cambias de implementación (p. ej. a Envoy Gateway) tendrás
> que traducirlas a sus CRDs equivalentes. El enrutamiento (`HTTPRoute`) sí es portable.
