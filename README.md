# Escenarios Killercoda: temas nuevos de certificaciones Kubernetes

Escenarios interactivos para [Killercoda](https://killercoda.com) que cubren temas añadidos
recientemente a los temarios de CKA / CKAD y que no estaban cubiertos por los escenarios existentes.

| Escenario | Temas | Duración |
|---|---|---|
| [`gateway-api-nginx-fabric`](gateway-api-nginx-fabric) | Gateway API con NGINX Gateway Fabric v2.7.2: Gateway compartido, `allowedRoutes`, `HTTPRoute`, canary, filtros, TLS, `RateLimitPolicy`, `ReferenceGrant` | ~45 min |
| [`gateway-api-envoy`](gateway-api-envoy) | Gateway API con Envoy Gateway v1.9.2: `EnvoyProxy`, migración de Ingress (`ingress2gateway`), `RequestMirror`, timeouts, `BackendTrafficPolicy`, `SecurityPolicy`, `egctl` | ~45 min |

## Estructura

```
<escenario>/
├── index.json          # metadatos, pasos e imagen (kubernetes-kubeadm-1node)
├── intro.md / finish.md
├── setup/
│   ├── background.sh   # despliega las apps de ejemplo durante la intro
│   └── foreground.sh   # espera a que el entorno esté listo
├── assets/             # manifiestos copiados a /root/assets
└── stepN/
    ├── text.md         # teoría + tarea + solución plegable
    ├── verify.sh       # botón "Check" (exit 0 = superado)
    └── background.sh   # (opcional) prepara escenarios de troubleshooting
```

`structure.json` define el orden de los escenarios en el perfil de Killercoda.

## Publicar

1. Sube este directorio a un repositorio de GitHub.
2. En Killercoda → *Creator* → *Repository*, conecta el repositorio y añade la deploy key/webhook.
3. Cada `push` actualiza los escenarios.

## Actualizar versiones

Las versiones están fijadas en los `text.md` y `background.sh`:

```bash
grep -rn 'v2.7.2\|v1.9.2\|v1.2.0\|echo-basic' .
```

Probados de extremo a extremo (todos los comandos de solución + `verify.sh`) en un clúster `kind`
con Kubernetes 1.34 el 2026-09-29.
