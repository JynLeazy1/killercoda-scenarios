# Gateway API with NGINX Gateway Fabric - Part 2: Advanced

This lab continues **Part 1: Fundamentals**. You don't need to repeat anything: while you read this,
the environment is rebuilt exactly as Part 1 left it.

## Already in place

| Resource | Details |
|---|---|
| NGINX Gateway Fabric v2.7.2 | GatewayClass `nginx`, data plane exposed on NodePorts **30080** (HTTP) and **30443** (HTTPS) |
| Gateway `cafe-gw` (namespace `infra`) | `http` listener on port 80, accepts routes from namespaces labeled `shared-gateway-access=true` |
| Namespace `cafe` (labeled) | Apps `coffee-v1`, `coffee-v2` and `tea` |
| HTTPRoute `coffee` | `/coffee` → 80% v1 / 20% v2, and header `x-version: v2` → v2 |
| HTTPRoute `tea` | `Exact /tea` → `tea` |

## What you will do

1. Use filters: modify headers, rewrite URLs and redirect
2. Terminate TLS and redirect HTTP → HTTPS
3. Apply rate limiting with an NGF-specific policy
4. Troubleshoot broken routes (`ReferenceGrant`, `ResolvedRefs`)
