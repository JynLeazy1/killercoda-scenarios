# SecurityPolicy: basic authentication

`SecurityPolicy` centralizes authentication and authorization at the Gateway: **Basic Auth**,
**JWT**, **OIDC**, **API Key**, **external authorization**, **CORS** and **authorization** rules by
IP or claims. Applications don't need to implement anything.

### 1. Credentials

Envoy requires the `htpasswd` format with a **SHA** hash, and the Secret must use the key `.htpasswd`:

```bash
echo "admin:{SHA}$(printf 'gateway123' | openssl dgst -binary -sha1 | openssl base64)" > .htpasswd
cat .htpasswd
kubectl create secret generic shop-basic-auth -n apps --from-file=.htpasswd
```{{exec}}

### 2. Task

Create a `SecurityPolicy` named `shop-auth` that requires Basic Auth (Secret `shop-basic-auth`) on
the `shop` route.

<details>
<summary>Solution</summary>

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

### Try it

```bash
curl -s -o /dev/null -w "no credentials    -> %{http_code}\n" -H "Host: shop.example" http://$NODE_IP:$GW_PORT/
curl -s -o /dev/null -w "wrong password    -> %{http_code}\n" -u admin:wrong -H "Host: shop.example" http://$NODE_IP:$GW_PORT/
curl -s -o /dev/null -w "valid credentials -> %{http_code}\n" -u admin:gateway123 -H "Host: shop.example" http://$NODE_IP:$GW_PORT/
curl -s -o /dev/null -w "other route (web) -> %{http_code}\n" -H "Host: www.example" http://$NODE_IP:$GW_PORT/
```{{exec}}

> **Policy hierarchy:** a policy attached to a **route** takes precedence over one attached to the
> **Gateway**. This way the platform team can set a default behavior and each team can tune it for
> its own routes.
>
> The `web` route doesn't ask for credentials (it may return `429` if the per-minute limit from the
> previous step hasn't reset yet: that's a different policy, on a different route).
