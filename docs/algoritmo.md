# Contrato del algoritmo (compartido)

Este documento es la **fuente de verdad** para las tres implementaciones (C, Pascal, Fortran). Los diagramas Nassi-Shneiderman (`docs/nassi-schneiderman/`) reflejan exactamente esta descomposición: **un diagrama por módulo**, y cada programa tiene **un procedimiento/función por diagrama**, con el mismo nombre y los mismos parámetros.

## Entrada (obligatoria)

| Parámetro | Nombre | Unidad | Validación |
|-----------|--------|--------|------------|
| Peso (masa) del paracaidista | `masa_paracaidista` | kg | \(> 0\) |
| Peso (masa) de la impedimenta | `masa_impedimenta` | kg | \(\ge 0\) |
| Altura de salto | `altura` | m | \(> 0\) |

Además se pide el **modo**:

| Modo | Significado |
|------|-------------|
| 1 | Simular con \(\beta\) dado por el usuario (se pide \(\beta > 0\)) |
| 2 | Investigación: el algoritmo busca \(\beta\) hasta \(v_{\mathrm{suelo}} \approx v_{\mathrm{meta}}\) |

El enunciado expresa los “pesos” en kg; se tratan como **masas** y \(W = (m_p + m_i)\,g\) en newtons (ver `modelo-matematico.md`).

## Parámetros internos (congelados — mismos valores en los 3 lenguajes)

| Constante | Valor | Notas |
|-----------|-------|-------|
| `G` | `9.81` | m/s² |
| `H_PASO` | `0.1` | s — paso RK4 fijo |
| `V_META` | `20.0/9.0` (≈ 2.2222) | m/s — 8 km/h |
| `TOL_V` | `0.05` | m/s — tolerancia de \(v_{\mathrm{suelo}}\) en la búsqueda |
| `BETA_LO` | `1.0` | N·s/m — extremo inferior de la bisección |
| `Z_ESTABLE` | `2.0` | factor para el extremo superior: `beta_hi = Z_ESTABLE · W / (g · h)` |
| `MAX_ITER_BETA` | `60` | iteraciones máx. de bisección |
| `IMPRIMIR_CADA` | `50` | una fila de tabla cada 50 pasos (5 s) + fila inicial + fila de aterrizaje |
| `MAX_PASOS` | `200000` | pasos RK4 máx. por simulación (20 000 s) |
| `MAX_FILAS` | `MAX_PASOS / IMPRIMIR_CADA + 2` | capacidad de la tabla |

### ¿Por qué `beta_hi` no es una constante fija?

La EDO \(v' = g - (\beta g / W)\,v\) tiene autovalor \(\lambda = -\beta g/W\). RK4 explícito sólo es estable si \(|h\lambda| \lesssim 2.785\). Con el valor fijo anterior (`beta_hi = 5000`) y \(m = 130\) kg resulta \(h\beta g/W = 3.85\): **la integración diverge** (se obtenía \(v \approx -6572\) m/s y un “aterrizaje” falso a los 0.84 s). Definir `beta_hi = 2·W/(g·h)` garantiza \(|h\lambda| = 2\) (zona estable) para **cualquier** masa, y además
\(v_{\mathrm{suelo}}(\beta_{hi}) \approx W/\beta_{hi} = g h / 2 \approx 0.49\) m/s \(< v_{\mathrm{meta}}\), por lo que el intervalo siempre encierra la solución.

## Salida

1. Tabla \(t_i, v_i, x_i\) (fila inicial, cada `IMPRIMIR_CADA` pasos y la de aterrizaje) con columnas analíticas \(v(t), x(t)\) para verificar el RK4.
2. Resumen: masas, \(W\), \(H\), \(\beta\) (usado o encontrado), \(t_{\mathrm{suelo}}\), \(x_{\mathrm{suelo}}\), \(v_{\mathrm{suelo}}\) en m/s y km/h, pasos y \(h\).
3. En modo investigación: \(\beta\) encontrado, \(v_{\mathrm{meta}}\), y aviso si no se alcanzó la tolerancia.

## Estructuras de datos

| Registro | Campos |
|----------|--------|
| `Entrada` | `modo`, `masa_paracaidista`, `masa_impedimenta`, `altura`, `beta` |
| `Fila` | `t`, `v`, `x` |
| `ResultadoCaida` | `aterrizo` (lógico), `t_suelo`, `v_suelo`, `x_suelo`, `pasos`, `n_filas`, `filas[1..MAX_FILAS]` de `Fila` |

## Módulos (bajo coupling, alta cohesión)

Toda la comunicación es **por parámetros** (acoplamiento de datos). No hay variables globales modificables; sólo constantes. **Ningún módulo de cálculo hace E/S** y **ningún módulo recibe banderas de control** que alteren su comportamiento.

| Módulo | Entradas | Salidas | Responsabilidad única | No hace |
|--------|----------|---------|-----------------------|---------|
| `leer_entrada` | — | `e: Entrada`, `ok` | Pedir y validar modo, 3 parámetros y \(\beta\) (modo 1) | calcular física |
| `peso_total` | `masa_p`, `masa_i`, `g` | `W` | \(W=(m_p+m_i)g\) | E/S |
| `f_velocidad` | `v`, `g`, `beta`, `W` | \(dv/dt\) | Lado derecho de la EDO: \(g-(\beta g/W)v\) | E/S, integrar |
| `paso_rk4` | `h`, `v`, `x`, `g`, `beta`, `W` | `v_sig`, `x_sig` | Un paso RK4 del sistema \(v'=f(v)\), \(x'=v\) | E/S, decidir cuándo parar |
| `registrar_fila` | `r`, `t`, `v`, `x` | `r` (modificado) | Agregar una fila a la tabla de `r` | calcular, E/S |
| `integrar_caida` | `W`, `beta`, `altura`, `g`, `h` | `r: ResultadoCaida` | Avanzar con `paso_rk4` hasta \(x \ge H\), recortar el último paso, guardar filas | E/S, buscar \(\beta\) |
| `buscar_beta` | `W`, `altura`, `g`, `h`, `v_meta`, `tol_v` | `beta`, `encontrado` | Bisección de \(\beta\) usando `integrar_caida` | E/S, reimplementar RK4 |
| `v_analitica` | `t`, `W`, `beta`, `g` | \(v(t)\) | Solución cerrada (verificación) | E/S |
| `x_analitica` | `t`, `W`, `beta`, `g` | \(x(t)\) | Solución cerrada (verificación) | E/S |
| `mostrar_tabla` | `r`, `W`, `beta`, `g` | — (pantalla) | Imprimir la tabla numérica vs. analítica | integrar |
| `mostrar_salida` | `e`, `W`, `beta`, `r`, `h`, `v_meta` | — (pantalla) | Imprimir el resumen (el texto de \(\beta\) depende de `e.modo`) | calcular |
| `main` | — | código de salida | Orquestar el flujo | fórmulas físicas, RK4 |

Diagrama de llamadas:

```
main ─┬─ leer_entrada
      ├─ peso_total
      ├─ buscar_beta ──── integrar_caida
      ├─ integrar_caida ─┬─ paso_rk4 ── f_velocidad
      │                  └─ registrar_fila
      ├─ mostrar_tabla ──┬─ v_analitica
      │                  └─ x_analitica
      └─ mostrar_salida
```

## Notas de diseño

- **Programación estructurada estricta:** sólo secuencia, selección e iteración; **una entrada y una salida por módulo** (sin `return`/`exit`/`break` a mitad de un bloque). Los ciclos terminan por su condición (`MIENTRAS NO aterrizo Y i < MAX_PASOS`, `MIENTRAS NO encontrado Y iter < MAX_ITER_BETA`).
- El sistema \(v'=f(v)\), \(x'=v\) se integra con **RK4 acoplado** (las pendientes de \(x\) usan las velocidades intermedias del RK4 de \(v\)). La EDO es **autónoma** (\(f\) no depende de \(t\)), por eso \(t\) no se pasa a `f_velocidad` ni a `paso_rk4`.
- Invariante del ciclo de `integrar_caida`: \(x < H\). Si el paso completo da \(x_{sig} \ge H\), entonces \(x_{sig} - x > 0\) y \(\mathit{frac}=(H-x)/(x_{sig}-x) \in (0,1]\); se **rehace** el paso con \(h\cdot\mathit{frac}\) para estimar \(t_{\mathrm{suelo}}\), \(v_{\mathrm{suelo}}\).
- `integrar_caida` **siempre** guarda la tabla; quien no la necesite (p. ej. `buscar_beta`) simplemente la ignora. Así se evita el acoplamiento de control de una bandera `verbose`.
- `buscar_beta` sólo evalúa \(v_{\mathrm{suelo}}(\beta)\) llamando a `integrar_caida`. Más \(\beta\) ⇒ más resistencia ⇒ menor \(v_{\mathrm{suelo}}\): si \(v_{mid} > v_{\mathrm{meta}}\) se sube `lo`, si no se baja `hi`.

## Flujo principal

1. `leer_entrada` → `e`, `ok`. Si no `ok`: mensaje y código 1.
2. `W ← peso_total(...)`.
3. Modo 1: `beta ← e.beta`, `encontrado ← verdadero`. Modo 2: `buscar_beta(...) → beta, encontrado` (si no `encontrado`, avisar “mejor aproximación”).
4. `integrar_caida(W, beta, ...) → r`.
5. Si `r.aterrizo`: `mostrar_tabla`, `mostrar_salida`. Si no: mensaje de error.

## Resultado de referencia (modo 2, 80 kg + 50 kg, 1500 m)

| Magnitud | Valor |
|----------|-------|
| \(W\) | 1275.3 N |
| \(\beta_{hi}\) | 2600.0 N·s/m |
| \(\beta\) encontrado | ≈ 569.5 N·s/m (5 iteraciones) |
| \(v_{\mathrm{suelo}}\) | ≈ 2.239 m/s ≈ 8.06 km/h |
| \(t_{\mathrm{suelo}}\) | ≈ 670 s |

Valor teórico (velocidad límite \(W/\beta = v_{\mathrm{meta}}\)): \(\beta^* = 1275.3 / 2.2222 \approx 573.9\) N·s/m. La diferencia se debe a `TOL_V = 0.05` m/s (≈ 0.18 km/h); una tolerancia menor acerca \(\beta\) a \(\beta^*\).

## Criterios de calidad (evaluación del curso)

- **Cohesión (binding):** cada módulo con un propósito claro (cohesión funcional).
- **Coupling:** sólo de datos; sin estado global modificable ni banderas de control.
- Las tres versiones siguen el **mismo** diagrama NS.

## Estado

- [x] Diagramas NS por módulo (`docs/nassi-schneiderman/*.md`) + código Structorizer (`docs/nassi-schneiderman/structorizer/*.nsd`)
- [x] Parámetros congelados (con `beta_hi` derivado de la estabilidad de RK4)
- [x] Implementaciones C, Pascal y Fortran alineadas a este contrato
- [ ] Validación cruzada compilando las tres versiones (mismos inputs → mismas salidas) — pendiente del equipo
