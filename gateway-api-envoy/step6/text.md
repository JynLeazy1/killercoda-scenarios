# SecurityPolicy: autenticación básica

`SecurityPolicy` centraliza autenticación y autorización en el Gateway: **Basic Auth**, **JWT**,
**OIDC**, **API Key**, **autorización externa**, **CORS** y reglas de **authorization** por IP o
claims. Las aplicaciones no necesitan implementar nada.

### 1. Credenciales

Envoy exige el formato `htpasswd` con hash **SHA**, y el Secret debe tener la clave `.htpasswd`:

```bash
echo "admin:{SHA}$(printf 'gateway123' | openssl dgst -binary -sha1 | openssl base64)" > .htpasswd
cat .htpasswd
kubectl create secret generic shop-basic-auth -n apps --from-file=.htpasswd
```{{exec}}

### 2. Tarea

Crea una `SecurityPolicy` llamada `shop-auth` que exija Basic Auth (Secret `shop-basic-auth`) en la
ruta `shop`.

<details>
<summary>Solución</summary>

```bash
cat <<'YAML' | kubectl apply -f -
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: SecurityPolicy
metadata:
  name: shop-auth
  namespace: apps
spec:
  targetRefs:
  - group: gateway.networking.k8s.io
    kind: HTTPRoute
    name: shop
  basicAuth:
    users:
      name: shop-basic-auth
YAML
```{{exec}}

</details>

### Pruébalo

```bash
curl -s -o /dev/null -w "sin credenciales  -> %{http_code}\n" -H "Host: shop.example" http://$NODE_IP:$GW_PORT/
curl -s -o /dev/null -w "password erróneo  -> %{http_code}\n" -u admin:mal -H "Host: shop.example" http://$NODE_IP:$GW_PORT/
curl -s -o /dev/null -w "con credenciales  -> %{http_code}\n" -u admin:gateway123 -H "Host: shop.example" http://$NODE_IP:$GW_PORT/
curl -s -o /dev/null -w "otra ruta (web)   -> %{http_code}\n" -H "Host: www.example" http://$NODE_IP:$GW_PORT/
```{{exec}}

> **Jerarquía de políticas:** una política adjunta a una **ruta** tiene prioridad sobre la adjunta al
> **Gateway**. Así el equipo de plataforma puede fijar un comportamiento por defecto y cada equipo
> ajustarlo para sus rutas.
>
> La ruta `web` no pide credenciales (puede devolver `429` si aún no se renovó el límite por minuto
> del paso anterior: es otra política, en otra ruta).
