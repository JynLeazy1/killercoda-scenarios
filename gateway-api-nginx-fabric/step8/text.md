# Troubleshooting: ReferenceGrant y ResolvedRefs

Un compañero creó la ruta `bakery` (namespace `cafe`) para publicar el servicio `bread` del namespace
`bakery` en `http://bakery.example`, pero **no funciona**:

```bash
curl -s -o /dev/null -w "%{http_code}\n" -H "Host: bakery.example" http://$NODE_IP:30080/
```{{exec}}

### Tarea

Haz que `curl -H "Host: bakery.example" http://$NODE_IP:30080/` devuelva **200** con la respuesta del
pod `bread`. **No** muevas la ruta de namespace ni cambies el Service `bread`.

### Metodología

1. ¿La ruta está aceptada por el Gateway? → condición `Accepted`
2. ¿Sus referencias a backends son válidas? → condición `ResolvedRefs`
3. ¿Los backends existen, en el puerto correcto, con endpoints?

```bash
kubectl get httproute bakery -n cafe -o jsonpath='{range .status.parents[*].conditions[*]}{.type}={.status} ({.reason}): {.message}{"\n"}{end}'
```{{exec}}

```bash
kubectl get svc,endpointslices -n bakery
```{{exec}}

<details>
<summary>Pista 1</summary>

Una ruta que apunta a un Service de **otro namespace** necesita que el dueño de ese namespace lo
autorice con un `ReferenceGrant` (razón `RefNotPermitted`). El grant vive en el namespace **destino**.

</details>

<details>
<summary>Pista 2</summary>

Después del grant, vuelve a revisar el status. ¿Existe un Service llamado `bread-svc`? ¿Qué puerto
expone realmente el Service `bread`?

</details>

<details>
<summary>Solución</summary>

```bash
cat <<'YAML' | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1beta1
kind: ReferenceGrant
metadata:
  name: allow-cafe-routes
  namespace: bakery
spec:
  from:
  - group: gateway.networking.k8s.io
    kind: HTTPRoute
    namespace: cafe
  to:
  - group: ""
    kind: Service
    name: bread
YAML

kubectl patch httproute bakery -n cafe --type=json -p '[
  {"op":"replace","path":"/spec/rules/0/backendRefs/0/name","value":"bread"},
  {"op":"replace","path":"/spec/rules/0/backendRefs/0/port","value":8080}
]'
```{{exec}}

</details>

Verifica:

```bash
kubectl get httproute bakery -n cafe -o jsonpath='{range .status.parents[*].conditions[*]}{.type}={.status} ({.reason}){"\n"}{end}'
curl -s -H "Host: bakery.example" http://$NODE_IP:30080/ | grep -E '"(namespace|pod)"'
```{{exec}}

> **Resumen de razones frecuentes en `status`**
>
> | Condición / razón | Causa típica |
> |---|---|
> | `Accepted=False` `NotAllowedByListeners` | El namespace de la ruta no cumple `allowedRoutes` |
> | `Accepted=False` `NoMatchingListenerHostname` | Los `hostnames` de la ruta no encajan con el listener |
> | `Accepted=False` `NoMatchingParent` | `sectionName`/`port` no existe en el Gateway |
> | `ResolvedRefs=False` `RefNotPermitted` | Falta `ReferenceGrant` para la referencia cruzada |
> | `ResolvedRefs=False` `BackendNotFound` | El Service no existe (o puerto incorrecto) |
> | *status vacío* | Ningún controlador reconoce el `parentRef` (nombre/namespace erróneo) |
