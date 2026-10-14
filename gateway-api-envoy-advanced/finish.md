# Scenario complete!

In this part you practiced:

* Standard `HTTPRoute` `timeouts`
* `BackendTrafficPolicy`: retries and local rate limiting
* `SecurityPolicy`: Basic Auth
* Troubleshooting with `status`, `egctl x status` and `egctl config envoy-proxy`

### NGINX Gateway Fabric vs Envoy Gateway

| | NGINX Gateway Fabric | Envoy Gateway |
|---|---|---|
| Data plane | NGINX | Envoy |
| Where the data plane is created | The `Gateway`'s namespace | `envoy-gateway-system` |
| Class parameters | `NginxProxy` | `EnvoyProxy` |
| Rate limiting | `RateLimitPolicy` | `BackendTrafficPolicy.rateLimit` |
| Authentication | `AuthenticationFilter` | `SecurityPolicy` |
| Troubleshooting CLI | — (`kubectl`, logs) | `egctl` |

**Portable** across both: `GatewayClass`, `Gateway`, `HTTPRoute`, `ReferenceGrant`, standard
filters, `weight` and `timeouts`. **Not portable**: each implementation's policies.
