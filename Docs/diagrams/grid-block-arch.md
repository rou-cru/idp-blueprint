## Legends and explicit keys

Even with consistent semantics, a grid map benefits from an explicit legend,
especially for:

- Color → domain/concern (e.g. Observability, Security, Delivery).  
- Special shapes or styles → “this block is a separator”, “this edge is
  conceptual”, etc.

In D2, legends can be defined via `vars.d2-legend`, for example:

```d2
```d2
direction: right

Legend: {
  Infra: "Infra core\n#0f172a / #38bdf8"
  Services: "Platform services\n#0f766e / #34d399"
  Governance: "Automation & governance\n#111827 / #6366f1"
  UX: "Developer-facing\n#7c3aed / #a855f7"
}
```
```

Guidelines for using legends with the grid:

- Use the legend to **document the mapping** from:
  - Fill colors → domains/concerns.  
  - Special shapes/styles → separators or auxiliary constructs.
- The legend should **not introduce new semantics** that contradict this file;
  it only makes the existing rules explicit for the reader.  
- Keep the legend compact and focused on what the user actually sees in the
  diagram (no exhaustive lists of components or implementation details).

## Dimensiones Adicionales: Estado y Exposición

Además de las dimensiones de capas (vertical) y dominios (horizontal/color), se incorporan dos dimensiones adicionales para enriquecer la información del mapa arquitectónico. Estas dimensiones se representan mediante estilos visuales específicos en los bloques.

### Dimensión de Estado (Stateful vs. Stateless)

Esta dimensión clasifica a los componentes según si gestionan o no un estado persistente. Es crucial para entender la resiliencia, las estrategias de backup y la complejidad operativa.

-   **Stateful:** Componentes que almacenan datos persistentes y cuyo estado es crítico para su funcionamiento.
    -   **Representación Visual:** El bloque del componente tendrá un **borde de línea continua**.
    -   *Ejemplos:* Bases de datos (PostgreSQL, Redis), almacenes de logs (Loki), almacenes de métricas (Prometheus), gestores de secretos (Vault).

-   **Stateless:** Componentes que no almacenan estado persistente o cuyo estado puede ser reconstruido fácilmente.
    -   **Representación Visual:** El bloque del componente tendrá un **borde de línea discontinua**.
    -   *Ejemplos:* Motores de políticas (Kyverno), controladores (ArgoCD), recolectores de logs (Fluent-bit), UIs.

### Dimensión de Exposición (Alcance de Red)

Esta dimensión clasifica a los componentes según su accesibilidad desde la red, distinguiendo entre servicios internos del clúster y aquellos expuestos externamente.

-   **Interno (Privado):** Componentes accesibles solo desde dentro del clúster.
    -   **Representación Visual:** Un icono de **candado 🔒** en la esquina inferior derecha del bloque.
    -   *Ejemplos:* Bases de datos, backends de servicios, controladores internos.

-   **Expuesto (Público):** Componentes accesibles desde fuera del clúster, típicamente a través de un Gateway o LoadBalancer.
    -   **Representación Visual:** Un icono de **mundo 🌐** en la esquina inferior derecha del bloque.
    -   *Ejemplos:* UIs de dashboards (Grafana, ArgoCD UI), APIs públicas.

---

## Practical grid manipulation in D2
