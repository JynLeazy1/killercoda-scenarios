# Migrar un Ingress a Gateway API

En `apps` existe un Ingress heredado (sin controlador que lo sirva):

```bash
kubectl get ingress shop -n apps -o yaml | sed -n '/^spec:/,$p'
```{{exec}}

### Equivalencias

| Ingress | Gateway API |
|---|---|
| `ingressClassName` | `Gateway.spec.gatewayClassName` + `HTTPRoute.spec.parentRefs` |
| `rules[].host` | `HTTPRoute.spec.hostnames` |
| `pathType: Prefix` | `path.type: PathPrefix` |
| `pathType: Exact` | `path.type: Exact` |
| `backend.service.name/port.number` | `backendRefs[].name/port` |
| `tls[].secretName` | `Gateway.spec.listeners[].tls.certificateRefs` |
| Anotaciones (`rewrite-target`, `ssl-redirect`, `canary`...) | Filtros estándar (`URLRewrite`, `RequestRedirect`, `weight`) o políticas de la implementación |

### Opción A: generar un borrador con `ingress2gateway`

La herramienta oficial de SIG-Network traduce Ingress (y muchas anotaciones) a recursos de Gateway API:

```bash
curl -sL https://github.com/kubernetes-sigs/ingress2gateway/releases/download/v1.2.0/ingress2gateway_Linux_x86_64.tar.gz | tar xz -C /usr/local/bin ingress2gateway
ingress2gateway print --providers ingress-nginx --namespace apps
```{{exec}}

Genera un `Gateway` propio y una `HTTPRoute`. Nosotros ya tenemos el Gateway `eg`, así que solo nos
interesa la ruta, cambiando su `parentRefs`.

### Tarea

Crea una `HTTPRoute` llamada `shop` en `apps`, adjunta al Gateway `eg`, que replique el Ingress:
`shop.example/api` → `api` y `shop.example/` → `web`.

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

```bash
curl -s -H "Host: shop.example" http://$NODE_IP:$GW_PORT/api/products | grep -E '"(path|pod)"'
curl -s -H "Host: shop.example" http://$NODE_IP:$GW_PORT/cart | grep -E '"(path|pod)"'
```{{exec}}

Una vez validada la ruta, el Ingress ya sobra:

```bash
kubectl delete ingress shop -n apps
```{{exec}}

> **Estrategia real de migración:** ejecutar ambos controladores en paralelo, crear las `HTTPRoute`,
> validar contra la IP del nuevo Gateway, mover el DNS y, al final, borrar los `Ingress`.
