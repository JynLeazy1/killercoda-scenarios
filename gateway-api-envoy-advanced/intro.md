# Gateway API with Envoy Gateway - Part 2: Policies

This lab continues **Part 1: Fundamentals**. You don't need to repeat anything: while you read this,
the environment is rebuilt exactly as Part 1 left it.

## Already in place

| Resource | Details |
|---|---|
| Envoy Gateway v1.9.2 | Control plane in `envoy-gateway-system` |
| GatewayClass `eg` | `parametersRef` → `EnvoyProxy` `nodeport-proxy` (data plane exposed as `NodePort`) |
| Gateway `eg` (namespace `apps`) | `http` listener on port 80 |
| HTTPRoute `web` | `www.example` → `web` |
| HTTPRoute `shop` | `shop.example/api` → 50% `api` / 50% `api-v2`, `shop.example/` → `web` (migrated from the old Ingress) |

The Envoy data plane's NodePort is saved in `$GW_PORT` and the node IP in `$NODE_IP`.

## What you will do

1. Apply timeouts, retries and rate limiting (`HTTPRoute` timeouts and `BackendTrafficPolicy`)
2. Protect a route with basic authentication using `SecurityPolicy`
3. Troubleshoot broken configuration with `status` and `egctl`
