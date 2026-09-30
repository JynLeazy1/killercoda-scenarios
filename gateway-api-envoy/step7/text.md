# Troubleshooting con status y egctl

Se desplegó la ruta `status` (host `status.example`) y la política `status-timeouts`, pero:

```bash
curl -s -o /dev/null -w "%{http_code}\n" -H "Host: status.example" http://$NODE_IP:$GW_PORT/
```{{exec}}

### Tarea

Consigue que `status.example` responda **200** y que la política `status-timeouts` quede
**aceptada** sobre esa ruta. No renombres los recursos existentes.

### Herramientas

**1. `status` de los recursos**

```bash
kubectl get httproute status -n apps -o yaml | sed -n '/^status:/,$p'
kubectl get btp status-timeouts -n apps -o yaml | sed -n '/^status:/,$p'
```{{exec}}

Un `status` **vacío** es una pista en sí misma: ningún controlador se ha hecho cargo del recurso.

**2. `egctl`**, la CLI de Envoy Gateway (ya instalada):

```bash
egctl x status all -n apps
```{{exec}}

Y para ver lo que Envoy tiene *realmente* cargado (rutas xDS):

```bash
egctl config envoy-proxy route -n envoy-gateway-system \
  -l gateway.envoyproxy.io/owning-gateway-name=eg -o yaml | grep -E 'name: httproute/|domains' -A1 | head -40
```{{exec}}

<details>
<summary>Pista</summary>

Compara `spec.parentRefs[0].name` de la ruta con los Gateways que existen (`kubectl get gateway -n apps`),
y el `targetRefs[0].name` de la política con el nombre real de la ruta.

</details>

<details>
<summary>Solución</summary>

```bash
kubectl patch httproute status -n apps --type=json \
  -p '[{"op":"replace","path":"/spec/parentRefs/0/name","value":"eg"}]'
kubectl patch btp status-timeouts -n apps --type=json \
  -p '[{"op":"replace","path":"/spec/targetRefs/0/name","value":"status"}]'
```{{exec}}

</details>

Verifica:

```bash
egctl x status httproute -n apps
kubectl get btp status-timeouts -n apps -o jsonpath='{range .status.ancestors[*].conditions[*]}{.type}={.status} ({.reason}){"\n"}{end}'
curl -s -o /dev/null -w "%{http_code}\n" -H "Host: status.example" http://$NODE_IP:$GW_PORT/
```{{exec}}

> Otros comandos útiles: `egctl config envoy-proxy all` (volcado completo de Envoy),
> `egctl x translate` (traduce YAML de Gateway API a xDS sin clúster) y los logs del control plane:
> `kubectl logs -n envoy-gateway-system deploy/envoy-gateway`.
