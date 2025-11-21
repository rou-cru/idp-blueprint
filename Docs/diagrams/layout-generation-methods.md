# Metodologías para la Generación Automática de Layouts de Grid

Este documento analiza diferentes metodologías algorítmicas para resolver el problema de generar un layout 2D para un conjunto de componentes arquitectónicos, respetando un conjunto de reglas semánticas definidas en `grid-block-arch.md`.

El problema se puede clasificar como un **Problema de Satisfacción de Restricciones (Constraint Satisfaction Problem - CSP)** con un componente de optimización espacial.

## Pre-requisito Común: Formalización de Elementos y Reglas

Antes de aplicar cualquier método, es fundamental tener un modelo de datos formal.

1. **Elementos (Componentes):** Cada componente a dibujar (ej. `Vault`, `ArgoCD`, `Plano de Observabilidad`) debe tener propiedades claras:
    - `id`: Nombre único del componente.
    - `capa_arquitectonica`: Ej. `Infraestructura`, `Servicios de Plataforma`, `Control`, `UX`. Define su posición vertical relativa.
    - `dominio`: Ej. `Seguridad`, `Delivery`, `Observabilidad`. Influye en la agrupación horizontal y el color.
    - `tipo_de_span`: Ej. `Puntual`, `Transversal_Capa`, `Plano_Vertical`. Define su comportamiento de expansión.
    - `dependencias_soporte`: Lista de IDs de elementos que este componente soporta (para la regla de dependencia vertical).

2. **Reglas Semánticas (Constraints):** Las reglas del `grid-block-arch.md` se deben convertir en funciones de validación que operan sobre el estado del grid:
    - `valida_capas(grid)`: Verifica que si el elemento A soporta a B, A está en una fila inferior a B.
    - `valida_peers(grid)`: Verifica que los elementos de la misma capa arquitectónica estén en la misma fila.
    - `valida_span(grid, elemento)`: Verifica que un elemento con span vertical ocupe varias filas contiguas.
    - `valida_colisiones(grid)`: Verifica que ningún par de elementos ocupe la misma celda del grid.
    - `valida_contiguidad(grid)`: Premia (o exige) que elementos del mismo dominio formen figuras contiguas (rectángulos, formas de L).

---

A continuación, se describen tres metodologías para abordar este problema.

## Método 1: Backtracking con Propagación de Restricciones (CSP)

Este método es una formalización del enfoque de "prueba y error" recursivo. Es un algoritmo exhaustivo que garantiza encontrar una solución si existe.

### Concepto

Se trata el grid como un conjunto de variables (la posición y dimensiones de cada componente) y un conjunto de restricciones (las reglas semánticas). El algoritmo intenta asignar un valor (una forma y posición) a cada variable, una por una. Si una asignación conduce a una contradicción, retrocede (backtrack) y prueba una alternativa.

### Proceso Detallado

1. **Inicialización:** Se define un canvas (ej. 12x12) y una lista de componentes sin asignar. Se ordenan los componentes del más al menos restrictivo (ej. primero los de infraestructura, luego los planos verticales, al final los puntuales).
2. **Asignación Recursiva:**
    - Se toma el siguiente componente de la lista.
    - Se itera sobre todas las posibles posiciones y formas válidas para ese componente.
    - Para cada posible asignación:
        a.  **Verificación de Consistencia:** Se comprueba si la nueva asignación entra en conflicto con los componentes ya colocados (`valida_colisiones`) y si cumple las reglas semánticas relativas a ellos.
        b.  **Propagación de Restricciones (Optimización):** Al colocar un componente, se reducen las opciones para los componentes futuros. Por ejemplo, si coloco `Infraestructura` en la fila 1, ningún componente de `UX` podrá ir en la fila 1. Esto poda drásticamente el árbol de búsqueda.
        c.  **Llamada Recursiva:** Si la asignación es consistente, se llama a la función para el siguiente componente.
3. **Backtrack:** Si se prueban todas las asignaciones para el componente actual y ninguna lleva a una solución, la función falla. Esto hace que la llamada anterior retroceda, deshaga la asignación del componente *anterior* y pruebe la siguiente opción para *ese* componente.
4. **Solución:** Se encuentra una solución cuando todos los componentes han sido asignados.

### Pros

- **Completo:** Si existe una solución, este método la encontrará garantizado.
- **Correcto:** La solución final cumplirá con todas las restricciones definidas.
- **Formal:** Es un enfoque algorítmicamente sólido y bien estudiado.

### Contras

- **Complejidad Exponencial:** Puede ser extremadamente lento para más de un puñado de componentes.
- **Sensible al Orden:** El orden en que se asignan los componentes puede tener un impacto dramático en el rendimiento.
- **Requiere un Canvas Finito:** Se debe predefinir un tamaño de grid.

---

## Método 2: Algoritmo Voraz (Greedy) con Heurísticas

Este es un enfoque más pragmático y rápido, que busca una solución "suficientemente buena" en lugar de la óptima.

### Concepto

En lugar de explorar todas las posibilidades, en cada paso se toma la decisión que parece "mejor" en ese momento y no se vuelve atrás. La clave está en definir qué es "mejor" a través de una heurística.

### Proceso Detallado

1. **Priorización:** Se ordenan los componentes a colocar según una heurística de "peso arquitectónico" o "dificultad de colocación" (ej. de más a menos restrictivo).
2. **Colocación Iterativa:** Se recorre la lista priorizada:
    - Para cada componente, se identifican todos los posibles lugares válidos en el grid actual.
    - **Función de Costo/Puntuación:** Se evalúa cada lugar válido con una heurística. Se puntúa mejor un lugar si, por ejemplo, minimiza el espacio en blanco, maximiza la contigüidad con su dominio, o crea una forma general más compacta.
    - Se elige la posición con la mejor puntuación, se coloca el componente ahí de forma definitiva y se pasa al siguiente.
3. **Manejo de Fallos:** Si para un componente no se encuentra ningún lugar válido, el algoritmo puede fallar o intentar una acción de recuperación, como expandir el canvas.

### Pros

- **Rápido y Eficiente:** Mucho más rápido que el backtracking, viable para un número mayor de componentes.
- **Simple de Implementar:** La lógica es directa, sin recursión compleja.
- **Intuitivo:** Emula cómo una persona podría resolver el puzzle: colocar primero las piezas más grandes.

### Contras

- **No Óptimo:** Puede llevar a soluciones subóptimas. Una decisión voraz temprana puede impedir encontrar una solución global mejor.
- **No Completo:** Puede fallar en encontrar una solución aunque exista.
- **Dependiente de la Heurística:** La calidad del resultado depende enteramente de la calidad de las funciones de priorización y puntuación.

---

## Método 3: Optimización Estocástica (ej. Algoritmo Genético)

Este es un enfoque inspirado en la biología que explora el espacio de soluciones de manera aleatoria pero guiada, útil para problemas de optimización muy complejos.

### Concepto

Se genera una "población" de layouts aleatorios. Los mejores se "cruzan" y "mutan" para crear una nueva generación, que debería ser, en promedio, mejor que la anterior. El proceso se repite hasta que se encuentra una solución satisfactoria.

### Proceso Detallado

1. **Inicialización:** Se crea una población de N layouts completamente aleatorios.
2. **Función de Fitness (Aptitud):** Se crea una función que califica qué tan "bueno" es un layout. Se aplican penalizaciones por cada regla rota (colisiones, violaciones de capa, etc.) y se pueden dar recompensas por propiedades deseables (compacidad).
3. **Ciclo Evolutivo:**
    - **Selección:** Se eligen los layouts con mejor puntuación (menor penalización) como "padres".
    - **Cruce (Crossover):** Se combinan dos padres para crear "hijos" (nuevos layouts).
    - **Mutación:** Se introducen pequeños cambios aleatorios en los hijos (ej. mover un componente).
4. **Terminación:** El ciclo se repite durante un número fijo de generaciones o hasta que un layout alcanza una puntuación de "aptitud" aceptable.

### Pros

- **Exploración Robusta:** Puede escapar de óptimos locales y encontrar soluciones no obvias en espacios de búsqueda enormes.
- **Flexible:** Puede manejar restricciones "suaves" (preferencias) y "duras" (requisitos) ajustando las penalizaciones.
- **Escalable:** Escala mejor que el backtracking para problemas muy grandes.

### Contras

- **No Garantiza Solución:** No hay garantía de que encuentre una solución válida, aunque exista.
- **No Determinista:** Dos ejecuciones pueden dar resultados diferentes.
- **Complejo de Ajustar:** Requiere una cuidadosa calibración de la función de fitness y otros parámetros.

## Resumen y Recomendación

| Característica | Backtracking (CSP) | Voraz (Greedy) con Heurísticas | Algoritmo Genético |
| :--- | :--- | :--- | :--- |
| **Calidad Solución** | Óptima / Garantizada | Subóptima / "Buena" | Buena / Potencialmente no obvia |
| **Garantía** | Completo (si la solución existe, la encuentra) | Incompleto (puede fallar) | Incompleto (puede no encontrarla) |
| **Velocidad** | Muy Lento | Muy Rápido | Lento a Moderado |
| **Complejidad Imp.** | Alta | Baja | Muy Alta |
| **Ideal para...** | Pocos componentes con reglas muy estrictas. | Prototipado rápido, muchos componentes. | Problemas muy grandes y complejos sin solución obvia. |

### Recomendación Práctica

1. **Empezar con el Método 2 (Voraz con Heurísticas):** Es el más pragmático para obtener resultados rápidos y visuales. Es probable que una solución "suficientemente buena" sea adecuada para empezar a dibujar.
2. **Si el Método 2 falla, considerar el Método 1 (Backtracking):** Si el número de componentes es manejable (<15-20) y se necesita una solución garantizada y correcta.
3. **Reservar el Método 3 (Algoritmo Genético) como una opción avanzada:** Para problemas extremadamente complejos donde los otros métodos no son viables.
