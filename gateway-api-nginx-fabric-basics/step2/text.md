# Create a shared Gateway

The platform team publishes **a single Gateway** in the `infra` namespace and decides which
namespaces may attach routes to it through `allowedRoutes`.

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
YAML
```{{exec}}

`allowedRoutes.namespaces.from` options:

| Value | Meaning |
|---|---|
| `Same` (default) | Only routes in the same namespace as the Gateway |
| `All` | Routes from any namespace |
| `Selector` | Only namespaces whose labels match the selector |

### Watch the provisioning

```bash
kubectl get gateway -n infra
kubectl get deploy,svc,pods -n infra
```{{exec}}

NGF created `cafe-gw-nginx` (Deployment and Service). Wait for the Gateway to be `PROGRAMMED=True`:

```bash
kubectl wait -n infra gateway/cafe-gw --for=condition=Programmed --timeout=120s
kubectl get svc cafe-gw-nginx -n infra
```{{exec}}

The Service exposes port 80 on NodePort **30080**. Save the node IP for testing:

```bash
export NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
curl -s -o /dev/null -w "%{http_code}\n" http://$NODE_IP:30080/
```{{exec}}

A `404` is expected: the Gateway is listening, but it has no routes yet.

> **Key Gateway conditions:** `Accepted` (the configuration is valid) and `Programmed`
> (the data plane has applied it). In the exam, `kubectl describe gateway` is your best friend.
