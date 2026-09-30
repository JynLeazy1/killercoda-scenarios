# Instalar Envoy Gateway

El `install.yaml` de cada release incluye **los CRDs de Gateway API** (canal experimental), los
**CRDs de Envoy Gateway** y el controlador. Por su tamaño se aplica con `--server-side`:

```bash
kubectl apply --server-side -f https://github.com/envoyproxy/gateway/releases/download/v1.9.2/install.yaml
kubectl wait --timeout=5m -n envoy-gateway-system deployment/envoy-gateway --for=condition=Available
```{{exec}}

> En producción lo habitual es Helm:
> `helm install eg oci://docker.io/envoyproxy/gateway-helm --version v1.9.2 -n envoy-gateway-system --create-namespace`

Mira los CRDs propios de Envoy Gateway:

```bash
kubectl api-resources --api-group=gateway.envoyproxy.io
```{{exec}}

| CRD | Para qué sirve |
|---|---|
| `EnvoyProxy` | Cómo se despliega el data plane (réplicas, tipo de Service, recursos, logs...) |
| `ClientTrafficPolicy` | Comportamiento entre cliente y Envoy (timeouts, HTTP/3, IP real...) |
| `BackendTrafficPolicy` | Entre Envoy y el backend (rate limit, retries, circuit breaking, LB...) |
| `SecurityPolicy` | Autenticación y autorización (Basic, JWT, OIDC, API Key, CORS...) |
| `EnvoyExtensionPolicy` | Extensiones (Wasm, ext_proc, Lua) |
| `EnvoyPatchPolicy` | Parches xDS de bajo nivel |

### Tarea: GatewayClass con parámetros

Por defecto Envoy Gateway crea Services `LoadBalancer`. En este laboratorio no hay balanceador, así
que crea:

1. Un `EnvoyProxy` llamado `nodeport-proxy` en `envoy-gateway-system` con Service tipo `NodePort`.
2. Una `GatewayClass` llamada `eg` con controlador `gateway.envoyproxy.io/gatewayclass-controller`
   que lo referencie en `parametersRef`.

<details>
<summary>Solución</summary>

```bash
cat <<'YAML' | kubectl apply -f -
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: EnvoyProxy
metadata:
  name: nodeport-proxy
  namespace: envoy-gateway-system
spec:
  provider:
    type: Kubernetes
    kubernetes:
      envoyService:
        type: NodePort
---
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: eg
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
  parametersRef:
    group: gateway.envoyproxy.io
    kind: EnvoyProxy
    name: nodeport-proxy
    namespace: envoy-gateway-system
YAML
```{{exec}}

</details>

```bash
kubectl get gatewayclass eg
```{{exec}}

> `parametersRef` es el mecanismo **estándar** de Gateway API para pasar configuración específica de
> la implementación. En NGF apunta a `NginxProxy`; en Envoy Gateway, a `EnvoyProxy`.
