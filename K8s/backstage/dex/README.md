# Dex OIDC Provider for Backstage

Este directorio contiene la configuración de Dex como proveedor OIDC local para autenticación en Backstage, eliminando la necesidad de servicios OAuth externos (GitHub, Azure AD, etc.).

## 📋 Descripción

Dex es un proveedor de identidad (IdP) que implementa OpenID Connect (OIDC) y permite autenticación portable sin depender de servicios cloud externos. Esta configuración es ideal para demos, desarrollo y ambientes aislados.

## 🔑 Usuarios de Demo

Los siguientes usuarios están pre-configurados:

| Usuario | Email | Password | Grupos | Permisos |
|---------|-------|----------|--------|----------|
| Admin | `admin@example.com` | `password` | admins, developers | Acceso completo |
| Developer | `developer@example.com` | `password` | developers | Acceso estándar |
| Guest | `guest@example.com` | `password` | guests | Solo lectura |

## 🚀 Despliegue

### Estrategia de Configuración Dinámica (Runtime Configuration)

> [!NOTE]
> **Contexto Técnico:** Dex utiliza un archivo de configuración estático (YAML) y no soporta nativamente la sustitución de variables de entorno. Además, los ConfigMaps de Kubernetes son inmutables durante su ciclo de vida.

Para soportar el entorno dinámico de este Blueprint (donde el `DNS_SUFFIX` cambia según la IP del host), implementamos el patrón **Runtime Config Generation**:

1. **Inyección de Variable:** El proceso de despliegue (`Task`) calcula el `DNS_SUFFIX` local e inyecta esta variable en el Pod de Dex mediante un parche en el `ApplicationSet` de ArgoCD.
2. **Generación al Vuelo:** El contenedor de Dex utiliza un script de inicio (wrapper) que:
   - Copia la plantilla de configuración desde `/etc/dex/cfg/config.yaml` (ConfigMap) a `/tmp`.
   - Reemplaza el literal `${DNS_SUFFIX}` con el valor real de la variable de entorno.
   - Inicia Dex apuntando a esta configuración generada.

Este enfoque garantiza que Dex funcione correctamente sin importar el dominio base, manteniendo la infraestructura como código y compatible con GitOps.

### Pre-requisitos

1. **Vault configurado** con el secret de Dex:
   ```bash
   vault kv put secret/backstage/app \
     dexClientSecret="backstage-demo-secret" \
     backendSecret="<existing-value>"
   ```
   Ver [VAULT-SETUP.md](./VAULT-SETUP.md) para más detalles.

2. **Task CLI** instalado para ejecutar los comandos de despliegue que manejan la sustitución de variables.

### Aplicar Manifiestos

La forma recomendada de desplegar es utilizando el Taskfile del proyecto, que orquesta todo el flujo:

```bash
# Desplegar todo el stack de Backstage (incluyendo Dex)
task stacks:backstage
```

Esto ejecutará internamente:
```bash
envsubst < applicationset-backstage.yaml | kubectl apply -f -
```

### Verificar Despliegue

```bash
# Verificar pods
kubectl get pods -n backstage | grep dex

# Verificar logs
kubectl logs -n backstage deployment/dex

# Verificar servicio
kubectl get svc -n backstage dex

# Verificar ingress
kubectl get ingress -n backstage dex
```

### Probar OIDC Discovery

```bash
curl https://dex.${DNS_SUFFIX}/.well-known/openid-configuration
```

Debe retornar JSON con configuración OIDC.

## 🏗️ Arquitectura

```
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│             │  OIDC   │              │  K8s    │             │
│  Backstage  ├────────►│     Dex      ├────────►│    Vault    │
│             │         │              │  Auth   │             │
└─────────────┘         └──────────────┘         └─────────────┘
      │                        │
      │                        │
      ▼                        ▼
 PostgreSQL              Static Users
 (sessions)              (in memory)
```

## 📦 Componentes

| Archivo | Descripción |
|---------|-------------|
| `dex-config.yaml` | ConfigMap con configuración de Dex (usuarios, clientes OAuth) |
| `dex-deployment.yaml` | Deployment del pod de Dex |
| `dex-service.yaml` | Service ClusterIP para acceso interno |
| `dex-ingress.yaml` | Ingress para acceso externo |
| `dex-serviceaccount.yaml` | Service Account para el pod |
| `kustomization.yaml` | Kustomize para aplicar todos los manifiestos |
| `VAULT-SETUP.md` | Documentación de configuración de Vault |

## ⚙️ Configuración

### Recursos

- **CPU**: 100m request / 200m limit
- **Memoria**: 128Mi request / 256Mi limit
- **Storage**: In-memory (sin persistencia)

### Puertos

- **5556**: HTTP (OIDC endpoints)
- **5558**: Telemetry/Health checks

### URLs

- **Issuer**: `https://dex.${DNS_SUFFIX}`
- **OIDC Discovery**: `https://dex.${DNS_SUFFIX}/.well-known/openid-configuration`
- **Authorization**: `https://dex.${DNS_SUFFIX}/auth`
- **Token**: `https://dex.${DNS_SUFFIX}/token`

## 🔐 Seguridad

> [!WARNING]
> Esta configuración usa contraseñas estáticas en ConfigMaps, adecuado para **demos y desarrollo únicamente**.
> 
> Para producción:
> - Migrar a Keycloak o auth0
> - Usar secrets encriptados
> - Implementar MFA
> - Rotar secrets regularmente

### Security Context

El deployment incluye:
- `runAsNonRoot: true`
- `readOnlyRootFilesystem: true`
- Drop de todas las capabilities
- Sin privilegios

## 🧪 Pruebas

### Login Manual

1. Navegar a: `https://backstage.${DNS_SUFFIX}`
2. Click en "Sign In"
3. Usar credenciales de cualquier usuario demo
4. Verificar redirección exitosa a Backstage

### Verificar Token

```bash
# Obtener token (requiere curl y jq)
TOKEN=$(curl -X POST https://dex.${DNS_SUFFIX}/token \
  -d "grant_type=password" \
  -d "username=admin@example.com" \
  -d "password=password" \
  -d "client_id=backstage" \
  -d "client_secret=backstage-demo-secret" \
  | jq -r .access_token)

echo $TOKEN
```

## 🔄 Actualización

Para cambiar usuarios o configuración:

1. Editar `dex-config.yaml`
2. Aplicar cambios:
   ```bash
   kubectl apply -f dex-config.yaml
   ```
3. Reiniciar Dex:
   ```bash
   kubectl rollout restart deployment/dex -n backstage
   ```

## 📚 Referencias

- [Dex Documentation](https://dexidp.io/docs/)
- [Backstage Auth Documentation](https://backstage.io/docs/auth/)
- [OpenID Connect Specification](https://openid.net/connect/)

## 🆘 Troubleshooting

### Dex no arranca

```bash
kubectl logs -n backstage deployment/dex
# Verificar errores de configuración en config.yaml
```

### Backstage no redirige a Dex

1. Verificar que `DEX_CLIENT_SECRET` existe en el secret:
   ```bash
   kubectl get secret backstage-app-secrets -n backstage -o jsonpath='{.data.DEX_CLIENT_SECRET}' | base64 -d
   ```

2. Verificar logs de Backstage:
   ```bash
   kubectl logs -n backstage deployment/backstage | grep -i oidc
   ```

### Error de redirect_uri mismatch

Verificar que el callback URL en `dex-config.yaml` coincide con:
```
https://backstage.${DNS_SUFFIX}/api/auth/oidc/handler/frame
```
