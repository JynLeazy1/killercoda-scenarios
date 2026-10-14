# Troubleshooting with status and egctl

The `status` route (host `status.example`) and the `status-timeouts` policy were deployed, but:

```bash
curl -s -o /dev/null -w "%{http_code}\n" -H "Host: status.example" http://$NODE_IP:$GW_PORT/
```{{exec}}

### Task

Make `status.example` respond **200** and get the `status-timeouts` policy **accepted** on that
route. Don't rename the existing resources.

### Tools

**1. Resource `status`**

```bash
kubectl get httproute status -n apps -o yaml | sed -n '/^status:/,$p'
kubectl get btp status-timeouts -n apps -o yaml | sed -n '/^status:/,$p'
```{{exec}}

An **empty** `status` is a clue in itself: no controller has picked up the resource.

**2. `egctl`**, the Envoy Gateway CLI (already installed):

```bash
egctl x status all -n apps
```{{exec}}

And to see what Envoy has *actually* loaded (xDS routes):

```bash
egctl config envoy-proxy route -n envoy-gateway-system \
  -l gateway.envoyproxy.io/owning-gateway-name=eg -o yaml | grep -E 'name: httproute/|domains' -A1 | head -40
```{{exec}}

<details>
<summary>Hint</summary>

Compare the route's `spec.parentRefs[0].name` with the Gateways that exist (`kubectl get gateway -n apps`),
and the policy's `targetRefs[0].name` with the route's actual name.

</details>

<details>
<summary>Solution</summary>

```bash
kubectl patch httproute status -n apps --type=json \
  -p '[{"op":"replace","path":"/spec/parentRefs/0/name","value":"eg"}]'
kubectl patch btp status-timeouts -n apps --type=json \
  -p '[{"op":"replace","path":"/spec/targetRefs/0/name","value":"status"}]'
```{{exec}}

</details>

Verify:

```bash
egctl x status httproute -n apps
kubectl get btp status-timeouts -n apps -o jsonpath='{range .status.ancestors[*].conditions[*]}{.type}={.status} ({.reason}){"\n"}{end}'
curl -s -o /dev/null -w "%{http_code}\n" -H "Host: status.example" http://$NODE_IP:$GW_PORT/
```{{exec}}

> Other useful commands: `egctl config envoy-proxy all` (full Envoy dump),
> `egctl x translate` (translates Gateway API YAML into xDS without a cluster) and the control
> plane logs: `kubectl logs -n envoy-gateway-system deploy/envoy-gateway`.
