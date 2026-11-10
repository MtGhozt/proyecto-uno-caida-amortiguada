# Contrato del algoritmo (compartido)

Este documento es la **fuente de verdad** para las tres implementaciones (C, Pascal, Fortran). Los diagramas Nassi-Shneiderman deben reflejar exactamente esta descomposición.

## Entrada (obligatoria)

| Parámetro | Nombre sugerido | Unidad |
|-----------|-----------------|--------|
| Peso/masa del paracaidista | `masa_paracaidista` | kg |
| Peso/masa de la impedimenta | `masa_impedimenta` | kg |
| Altura de salto | `altura` | m |

Además se pide el **modo**:

| Modo | Significado |
|------|-------------|
| 1 | Simular con \(\beta\) dado por el usuario |
| 2 | Investigación: buscar \(\beta\) hasta \(v_{\mathrm{suelo}} \approx v_{\mathrm{meta}}\) |

Parámetros internos / configurables (**congelados** — mismos valores en los 3 lenguajes):

| Parámetro | Valor | Notas |
|-----------|-------|-------|
| `g` | `9.81` | m/s² |
| `h` | `0.1` | s — tamaño de paso RK4 fijo |
| `v_meta` | `20.0/9.0` (≈ 2.222…) | m/s — 8 km/h |
| `tol_v` | `0.05` | m/s — tolerancia de \(v\) al suelo en búsqueda de \(\beta\) |
| `beta_lo` / `beta_hi` | `1.0` / `5000.0` | N·s/m — intervalo inicial de bisección |
| `max_iter_beta` | `60` | iteraciones máx. de bisección |
| `imprimir_cada` | `50` | filas de tabla: cada 50 pasos (5 s) + instante de aterrizaje |

`beta` en modo 1: lo pide el usuario. En modo 2: lo calcula `buscar_beta`.

## Salida mínima

1. Tabla o secuencia de \(t_i, v_i, x_i\) (cada `imprimir_cada` pasos y el instante de aterrizaje); opcionalmente columnas analíticas de verificación.
2. Velocidad al llegar al suelo (m/s y km/h).
3. En modo investigación: valor de \(\beta\) encontrado.

## Módulos (bajo coupling, alta cohesión)

Cada módulo hace **una** cosa. Comunicación preferible por parámetros (no variables globales).

| Módulo | Responsabilidad | No debe hacer |
|--------|-----------------|---------------|
| `leer_entrada` | Leer y validar modo + 3 parámetros (+ \(\beta\) si modo 1) | calcular física |
| `peso_total` | \(W = (m_p+m_i)\,g\) | integrar |
| `f_velocidad` | \(f(t,v)=g-(\beta g/W)v\) | I/O |
| `paso_rk4` | Un paso RK4 escalar genérico dados \(f,h,t,w\) | conocer el modelo de caída |
| `integrar_caida` | Avanzar el sistema \(v,x\) hasta \(x \approx H\) | pedir datos al usuario |
| `v_analitica` / `x_analitica` | Verificación opcional contra solución cerrada | I/O pesado |
| `buscar_beta` | Bisección de \(\beta\) hasta \(v_{\mathrm{suelo}} \approx v_{\mathrm{meta}}\) | reinventar RK4 (llama a `integrar_caida`) |
| `mostrar_salida` | Imprimir resumen de resultados | calcular |

## Notas de diseño (integración)

- Se integra el sistema \(\dfrac{dv}{dt}=f(t,v)\), \(\dfrac{dx}{dt}=v\) con **RK4 acoplado** hasta \(x \ge H\).
- El último paso se recorta (fracción del paso \(h\) + re-integración o interpolación) al cruzar el suelo para estimar \(t_{\mathrm{suelo}}\) y \(v_{\mathrm{suelo}}\).
- `paso_rk4` queda como paso **escalar** genérico (cohesión); `integrar_caida` orquesta el sistema \(v\)-\(x\) (puede usar un paso de sistema interno sin romper el contrato).
- `buscar_beta` solo evalúa \(v_{\mathrm{suelo}}(\beta)\) vía `integrar_caida` (sin tabla verbose) y hace bisección en \([\texttt{beta\_lo},\texttt{beta\_hi}]\).

## Flujo principal

1. Leer entrada (`leer_entrada`).
2. Calcular \(W\) (`peso_total`).
3. Si modo 1: integrar con \(\beta\) dado (`integrar_caida` verbose), `mostrar_salida`.
4. Si modo 2: `buscar_beta` → integrar de nuevo con tabla de verificación → `mostrar_salida` (incluye \(\beta\)).

## Criterios de calidad (evaluación del curso)

- **Cohesión (binding):** cada procedimiento con un propósito claro.
- **Coupling:** mínimo; preferir paso de parámetros; evitar estado global compartido entre módulos.
- Las tres versiones deben seguir el **mismo** diagrama NS.

## Estado

- [ ] Diagramas NS aprobados por el equipo (`docs/nassi-schneiderman/`) — borradores listos para revisión
- [x] Defaults de `h` y tolerancia de \(\beta\) congelados
- [x] Implementación C alineada (referencia en `src/c/`)
- [x] Implementación Pascal alineada (`src/pascal/`)
- [x] Implementación Fortran alineada (`src/fortran/`)
- [ ] Validación cruzada (mismos inputs → mismas salidas) — pendiente confirmación del equipo
