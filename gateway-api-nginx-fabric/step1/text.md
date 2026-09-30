# Instalar Gateway API y NGINX Gateway Fabric

La Gateway API **no viene incluida** en Kubernetes: sus recursos son CRDs que se instalan aparte.
Cada implementación soporta una versión concreta, así que usamos la que acompaña a NGF.

### 1. CRDs de Gateway API (canal *standard*)

```bash
kubectl kustomize "https://github.com/nginx/nginx-gateway-fabric/config/crd/gateway-api/standard?ref=v2.7.2" | kubectl apply -f -
```{{exec}}

Comprueba qué tipos nuevos hay en el clúster:

```bash
kubectl api-resources --api-group=gateway.networking.k8s.io
```{{exec}}

> El canal **standard** contiene recursos estables (`GatewayClass`, `Gateway`, `HTTPRoute`,
> `GRPCRoute`, `ReferenceGrant`...). El canal **experimental** añade cosas como `TCPRoute` o `TLSRoute`.

### 2. CRDs propios de NGF

NGF añade CRDs para su configuración y para *políticas* (rate limiting, timeouts, etc.):

```bash
kubectl apply --server-side -f https://raw.githubusercontent.com/nginx/nginx-gateway-fabric/v2.7.2/deploy/crds.yaml
```{{exec}}

### 3. El controlador

En este laboratorio no hay balanceador de carga externo, así que usamos el manifiesto que expone el
plano de datos como `NodePort`:

```bash
kubectl apply -f https://raw.githubusercontent.com/nginx/nginx-gateway-fabric/v2.7.2/deploy/nodeport/deploy.yaml
kubectl wait --timeout=5m -n nginx-gateway deployment/nginx-gateway --for=condition=Available
```{{exec}}

### 4. Revisa la GatewayClass

```bash
kubectl get gatewayclass
kubectl describe gatewayclass nginx
```{{exec}}

Debe mostrar `ACCEPTED=True`. Fíjate en `parametersRef`: apunta a un recurso `NginxProxy`, que es
donde NGF guarda la configuración del plano de datos (réplicas, tipo de Service, imagen...).

### 5. Fija los NodePorts

Para no tener que buscar puertos aleatorios, indica a NGF qué NodePort usar para cada puerto de listener:

```bash
kubectl patch nginxproxy nginx-gateway-proxy-config -n nginx-gateway --type merge -p '
{"spec":{"kubernetes":{"service":{"nodePorts":[
  {"port":30080,"listenerPort":80},
  {"port":30443,"listenerPort":443}
]}}}}'
```{{exec}}

> **Arquitectura de NGF 2.x:** el *control plane* (`nginx-gateway`) observa los recursos de Gateway API
> y, por **cada `Gateway`** que crees, aprovisiona un Deployment + Service de NGINX (el *data plane*)
> en el namespace del Gateway. Por eso todavía no ves ningún NGINX corriendo.
