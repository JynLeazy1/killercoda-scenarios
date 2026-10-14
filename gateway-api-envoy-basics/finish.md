# Part 1 complete!

You practiced:

* Installing Envoy Gateway and `parametersRef` → `EnvoyProxy`
* `Gateway` and `HTTPRoute` with Envoy as the data plane
* Migrating `Ingress` to `HTTPRoute` (by hand and with `ingress2gateway`)
* `RequestMirror` (shadow traffic) and traffic splitting with `weight`

**Next:** *Gateway API with Envoy Gateway - Part 2: Policies* starts from exactly this state
(Gateway `eg` and routes `web` and `shop`) and covers `HTTPRoute` timeouts,
`BackendTrafficPolicy` (retries, rate limiting), `SecurityPolicy` (basic auth) and
troubleshooting with `egctl`.
