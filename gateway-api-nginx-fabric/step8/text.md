# Troubleshooting: ReferenceGrant and ResolvedRefs

A teammate created the `bakery` route (namespace `cafe`) to publish the `bread` service from the
`bakery` namespace at `http://bakery.example`, but **it doesn't work**:

```bash
curl -s -o /dev/null -w "%{http_code}\n" -H "Host: bakery.example" http://$NODE_IP:30080/
```{{exec}}

### Task

Make `curl -H "Host: bakery.example" http://$NODE_IP:30080/` return **200** with the response from
the `bread` pod. Do **not** move the route to another namespace or change the `bread` Service.

### Method

1. Is the route accepted by the Gateway? → `Accepted` condition
2. Are its backend references valid? → `ResolvedRefs` condition
3. Do the backends exist, on the right port, with endpoints?

```bash
kubectl get httproute bakery -n cafe -o jsonpath='{range .status.parents[*].conditions[*]}{.type}={.status} ({.reason}): {.message}{"\n"}{end}'
```{{exec}}

```bash
kubectl get svc,endpointslices -n bakery
```{{exec}}

<details>
<summary>Hint 1</summary>

A route that points to a Service in **another namespace** needs the owner of that namespace to
authorize it with a `ReferenceGrant` (reason `RefNotPermitted`). The grant lives in the **target**
namespace.

</details>

<details>
<summary>Hint 2</summary>

After the grant, check the status again. Is there a Service called `bread-svc`? Which port does the
`bread` Service actually expose?

</details>

<details>
<summary>Solution</summary>

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

Verify:

```bash
kubectl get httproute bakery -n cafe -o jsonpath='{range .status.parents[*].conditions[*]}{.type}={.status} ({.reason}){"\n"}{end}'
curl -s -H "Host: bakery.example" http://$NODE_IP:30080/ | grep -E '"(namespace|pod)"'
```{{exec}}

> **Common `status` reasons**
>
> | Condition / reason | Typical cause |
> |---|---|
> | `Accepted=False` `NotAllowedByListeners` | The route's namespace doesn't satisfy `allowedRoutes` |
> | `Accepted=False` `NoMatchingListenerHostname` | The route's `hostnames` don't fit the listener |
> | `Accepted=False` `NoMatchingParent` | The `sectionName`/`port` doesn't exist on the Gateway |
> | `ResolvedRefs=False` `RefNotPermitted` | Missing `ReferenceGrant` for the cross-namespace reference |
> | `ResolvedRefs=False` `BackendNotFound` | The Service doesn't exist (or wrong port) |
> | *empty status* | No controller recognizes the `parentRef` (wrong name/namespace) |
