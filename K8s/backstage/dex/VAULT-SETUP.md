# Vault Setup para Dex Authentication

Este documento describe los secrets que deben configurarse en Vault para que Backstage pueda autenticarse con Dex.

## Secrets Requeridos

### Path: `secret/backstage/app`

Este path debe contener el secret compartido entre Backstage y Dex para el cliente OAuth.

```bash
vault kv put secret/backstage/app \
  backendSecret="<existing-backend-secret>" \
  dexClientSecret="backstage-demo-secret"
```

**Propiedades:**
- `backendSecret`: Secret para las cookies de sesión de Backstage (ya existente)
- `dexClientSecret`: **NUEVO** - Secret compartido con Dex para el cliente OAuth
  - Valor debe ser: `backstage-demo-secret`
  - Este valor debe coincidir con el `secret` configurado en `dex-config.yaml`

## Verificación

Para verificar que los secrets están correctamente configurados:

```bash
# Ver el secret (requiere permisos de lectura)
vault kv get secret/backstage/app

# Verificar que External Secrets sincroniza correctamente
kubectl get externalsecret backstage-app-secrets -n backstage
kubectl describe externalsecret backstage-app-secrets -n backstage

# Ver el secret sincronizado en Kubernetes
kubectl get secret backstage-app-secrets -n backstage -o yaml
```

## Notas de Seguridad

> [!WARNING]
> El valor `backstage-demo-secret` es un ejemplo para demo. En producción:
> - Generar un secret aleatorio fuerte (mínimo 32 caracteres)
> - No compartir el secret en repositorios
> - Rotar el secret periódicamente
> - Usar un secret manager apropiado

## Generación de Secret Seguro

Para producción, generar un secret aleatorio:

```bash
# Generar secret aleatorio de 32 bytes (Base64)
openssl rand -base64 32

# O usando pwgen
pwgen -s 64 1
```
