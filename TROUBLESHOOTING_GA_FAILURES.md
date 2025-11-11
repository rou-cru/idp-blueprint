# Troubleshooting GitHub Actions Failures

**Fecha:** 2025-11-11
**Contexto:** Post-migración de documentación

---

## Problemas Comunes y Soluciones

### 1. CI Workflow Falla - "paths-ignore" Issues

**Síntoma:** CI se ejecuta cuando no debería o no se ejecuta cuando debería.

**Causa:** El `paths-ignore` en `.github/workflows/ci.yaml` ahora ignora `docs/**` (directorio fuente) en lugar de ignorar el compilado.

**Solución:**
```yaml
# En .github/workflows/ci.yaml líneas 7-10
paths-ignore:
  - 'docs/**'           # Correcto - ignora cambios en documentación fuente
  - 'mkdocs.yml'
  - '**.md'
  - '.github/workflows/docs.yaml'
```

---

### 2. Docs Workflow Falla - "ln: failed to create symbolic link"

**Síntoma:** Error en paso "Prepare Devbox configuration"
```
ln: failed to create symbolic link 'devbox.json': File exists
```

**Causa:** El symlink ya existe y `ln -s` falla.

**Solución:** Ya está corregido con `ln -sf` (force):
```yaml
run: ln -sf devbox-minimal.json devbox.json
```

---

### 3. MkDocs Build Falla - "minify plugin not found"

**Síntoma:**
```
Error: Plugin 'minify' not found
```

**Causa:** Plugin `mkdocs-minify-plugin` con dependencias rotas.

**Solución:** Ya deshabilitado en `mkdocs.yml`:
```yaml
plugins:
  # - minify:  # Temporarily disabled
  #     minify_html: true
```

**Reinstalar (si necesario):**
```bash
pip install mkdocs-minify-plugin>=0.7.1
```

---

### 4. MkDocs Build Falla - "Strict mode: warnings found"

**Síntoma:**
```
WARNING - Doc file contains a link, but target not found
Aborted with 1 warnings in strict mode!
```

**Causa:** Links rotos o archivos no encontrados.

**Verificación:**
```bash
mkdocs build --strict
```

**Soluciones ya aplicadas:**
- ✅ Grafana link corregido: `grafana.md` → `grafana/index.md`
- ✅ Todos los paths actualizados en configs

---

### 5. GitHub Pages Deployment Falla - "No pages artifact"

**Síntoma:**
```
Error: No artifact found with name: github-pages
```

**Causa:** GitHub Pages no configurado como "GitHub Actions".

**Solución:**
1. Ir a: `Settings → Pages`
2. **Source**: Seleccionar "**GitHub Actions**" (no "Deploy from a branch")

---

### 6. Devbox Install Falla - "package not found"

**Síntoma:**
```
Error: package 'markdownlint-cli2@0.18.1' not found
```

**Causa:** Versión específica no disponible en nixpkgs.

**Solución:** Verificar `.devcontainer/devbox-minimal.json`:
```json
{
  "packages": [
    "markdownlint-cli2@0.18.1"  // Verificar disponibilidad
  ]
}
```

**Alternativa:** Usar versión sin pin:
```json
{
  "packages": [
    "markdownlint-cli2"  // Sin versión específica
  ]
}
```

---

### 7. Python Dependencies Install Falla

**Síntoma:**
```
ERROR: Failed building wheel for csscompressor, jsmin
```

**Causa:** Dependencias de `mkdocs-minify-plugin` incompatibles con Python 3.11+.

**Solución:** Ya aplicado - plugin deshabilitado.

**Alternativa:** Instalar sin minify:
```bash
pip install mkdocs>=1.5.3 mkdocs-material>=9.5.0 \
  mkdocs-git-revision-date-localized-plugin>=1.2.0 \
  mkdocs-glightbox>=0.3.5 pillow>=10.0.0 cairosvg>=2.7.0
```

---

### 8. Task Command Not Found

**Síntoma:**
```
task: command not found
```

**Causa:** Devbox no instalado correctamente o PATH no configurado.

**Solución:** Verificar que el paso de Devbox install se ejecute correctamente:
```yaml
- name: Install Devbox
  uses: jetpack-io/devbox-install-action@v0.11.0
  with:
    project-path: .devcontainer
    enable-cache: true
```

---

### 9. Chart.yaml Generation Falla

**Síntoma:**
```
⚠️ version: latest - WARNING: Could not extract version
```

**Causa:** Script no encuentra `config.toml` o versiones en kustomization.

**Solución:** Este es un warning, no un error. Componentes de infraestructura usan "latest".

**Fix (opcional):** Actualizar `config.toml` o kustomization.yaml con versiones.

---

### 10. Git Permissions Error en Docs Workflow

**Síntoma:**
```
Error: Permission denied (publickey)
fatal: Could not read from remote repository
```

**Causa:** Workflow antiguo intentaba hacer commit/push.

**Solución:** Ya corregido - nuevo workflow NO hace commit:
```yaml
# ❌ VIEJO (removido):
- git commit -m "docs: update"
- git push origin main

# ✅ NUEVO:
- uses: actions/upload-pages-artifact@v3
- uses: actions/deploy-pages@v4
```

---

## Verificación Rápida

### Checklist Pre-Merge

- [ ] `mkdocs build --strict` ejecuta sin errores localmente
- [ ] `site/index.html` y `site/sitemap.xml` existen
- [ ] GitHub Pages configurado como "GitHub Actions" (no branch)
- [ ] Workflow de docs NO tiene `git commit` ni `git push`
- [ ] `.gitignore` incluye `/site/` y `.cache/`
- [ ] `docs/` es el directorio fuente (no `docs_src/`)

### Comandos de Diagnóstico

```bash
# Test build local
mkdocs build --strict

# Verificar estructura
ls -la docs/
ls -la site/

# Test metadata generation
bash Scripts/generate-chart-metadata.sh

# Verificar git status
git status

# Verificar workflows
cat .github/workflows/docs.yaml | grep -A5 "upload-pages-artifact"
```

---

## Logs Útiles

Para obtener información detallada de fallos:

1. **GitHub Actions UI:**
   ```
   https://github.com/rou-cru/idp-blueprint/actions
   ```

2. **Ver logs de un run específico:**
   - Click en el workflow fallido
   - Click en el job que falló
   - Expandir el step con error
   - Copiar mensaje completo

3. **Buscar patrón de error común:**
   ```bash
   # En logs, buscar:
   - "Error:"
   - "FAILED"
   - "fatal:"
   - "Aborted"
   - "WARNING" (en strict mode)
   ```

---

## Contacto y Referencias

- **MkDocs Docs**: https://www.mkdocs.org/
- **Material Theme**: https://squidfunk.github.io/mkdocs-material/
- **GitHub Actions Docs**: https://docs.github.com/en/actions
- **Devbox Docs**: https://www.jetify.com/devbox/docs/

---

**Última actualización:** 2025-11-11
