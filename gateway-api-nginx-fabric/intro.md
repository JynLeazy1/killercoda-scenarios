# Gateway API con NGINX Gateway Fabric

La **Gateway API** es el sucesor de `Ingress` y ya forma parte de los temarios de **CKA** y **CKAD**
("usar Gateway API para gestionar tráfico de entrada"). En este escenario la vas a practicar con
**NGINX Gateway Fabric (NGF) v2.7**, la implementación de NGINX de la especificación.

## Modelo orientado a roles

| Recurso | Quién lo gestiona | Para qué sirve |
|---|---|---|
| `GatewayClass` | Proveedor de infraestructura | Define *qué* controlador implementa los Gateways (similar a `IngressClass`) |
| `Gateway` | Operador del clúster / plataforma | Punto de entrada: listeners, puertos, TLS y *qué namespaces* pueden conectarse |
| `HTTPRoute` | Equipo de aplicación | Reglas de enrutamiento: hosts, paths, headers, pesos y filtros |
| `ReferenceGrant` | Dueño del namespace destino | Autoriza referencias entre namespaces |

## Lo que vas a hacer

1. Instalar los CRDs de Gateway API y NGINX Gateway Fabric
2. Crear un `Gateway` compartido en el namespace `infra`
3. Conectar `HTTPRoute`s desde el namespace `cafe` (`allowedRoutes`)
4. Hacer un *canary* con pesos y match por header
5. Usar filtros: modificar headers, reescribir URLs y redirigir
6. Terminar TLS y redirigir HTTP → HTTPS
7. Aplicar rate limiting con una política propia de NGF
8. Diagnosticar rutas rotas (`ReferenceGrant`, `ResolvedRefs`)

> Mientras lees esto, se están desplegando las apps de ejemplo `coffee-v1`, `coffee-v2` y `tea`
> en el namespace `cafe`.
