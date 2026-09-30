# Gateway API with NGINX Gateway Fabric

**Gateway API** is the successor to `Ingress`, and it is now part of the **CKA** and **CKAD**
curricula ("use the Gateway API to manage ingress traffic"). In this scenario you practice it with
**NGINX Gateway Fabric (NGF) v2.7**, NGINX's implementation of the specification.

## Role-oriented model

| Resource | Managed by | Purpose |
|---|---|---|
| `GatewayClass` | Infrastructure provider | Defines *which* controller implements the Gateways (similar to `IngressClass`) |
| `Gateway` | Cluster / platform operator | Entry point: listeners, ports, TLS and *which namespaces* may attach |
| `HTTPRoute` | Application team | Routing rules: hosts, paths, headers, weights and filters |
| `ReferenceGrant` | Owner of the target namespace | Authorizes cross-namespace references |

## What you will do

1. Install the Gateway API CRDs and NGINX Gateway Fabric
2. Create a shared `Gateway` in the `infra` namespace
3. Attach `HTTPRoute`s from the `cafe` namespace (`allowedRoutes`)
4. Run a *canary* with weights and header matching
5. Use filters: modify headers, rewrite URLs and redirect
6. Terminate TLS and redirect HTTP → HTTPS
7. Apply rate limiting with an NGF-specific policy
8. Troubleshoot broken routes (`ReferenceGrant`, `ResolvedRefs`)

> While you read this, the sample apps `coffee-v1`, `coffee-v2` and `tea` are being deployed
> into the `cafe` namespace.
