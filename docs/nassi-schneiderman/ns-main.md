# NS — `main (programa principal)`

Orquesta el flujo según el modo. No conoce la fórmula de \(f\) ni el esquema RK4; sólo llama módulos.

| | |
|---|---|
| **Entradas** | — (los datos los obtiene `leer_entrada`) |
| **Salidas** | código de salida (0 = éxito, 1 = error) |
| **Llama a** | `leer_entrada`, `peso_total`, `buscar_beta`, `integrar_caida`, `mostrar_tabla`, `mostrar_salida` |
| **Structorizer** | [`structorizer/main.nsd`](structorizer/main.nsd) |

Firma: `caida_amortiguada`

```text
┌────────────────────────────────────────────────────────────────────────────────────────────┐
│ leer_entrada(e, ok)                                                                        │
├────────────────────────────────────────────────────────────────────────────────────────────┤
│╲                                            ok                                            ╱│
│ ╲ V                                                                                    F ╱ │
├─────────────────────────────────────────────────────────────────────────────┬──────────────┤
│ W ← peso_total(e.masa_paracaidista, e.masa_impedimenta, G)                  │ codigo ← 1   │
├─────────────────────────────────────────────────────────────────────────────┤              │
│╲                                e.modo = 1                                 ╱│              │
│ ╲ V                                                                     F ╱ │              │
├───────────────────────┬─────────────────────────────────────────────────────┤              │
│ beta ← e.beta         │ buscar_beta(W, e.altura, G, H_PASO,                 │              │
│ encontrado ← true     │             V_META, TOL_V, beta, encontrado)        │              │
│                       ├─────────────────────────────────────────────────────┤              │
│                       │╲                  not encontrado                   ╱│              │
│                       │ ╲ V                                             F ╱ │              │
│                       ├───────────────────────────────────────────────┬─────┤              │
│                       │ ESCRIBIR 'Aviso: no se alcanzó TOL_V;'        │ ∅   │              │
│                       │ ESCRIBIR 'se usa la mejor aproximación'       │     │              │
├───────────────────────┴───────────────────────────────────────────────┴─────┤              │
│ integrar_caida(W, beta, e.altura, G, H_PASO, r)                             │              │
├─────────────────────────────────────────────────────────────────────────────┤              │
│╲                                r.aterrizo                                 ╱│              │
│ ╲ V                                                                     F ╱ │              │
├───────────────────────────────────────────────┬─────────────────────────────┤              │
│ mostrar_tabla(r, W, beta, G)                  │ ESCRIBIR 'Sin aterrizaje'   │              │
├───────────────────────────────────────────────┤ codigo ← 1                  │              │
│ mostrar_salida(e, W, beta, r, H_PASO, V_META) │                             │              │
├───────────────────────────────────────────────┤                             │              │
│ codigo ← 0                                    │                             │              │
├───────────────────────────────────────────────┴─────────────────────────────┴──────────────┤
│ terminar el programa con código de salida codigo                                           │
└────────────────────────────────────────────────────────────────────────────────────────────┘
```

**Coupling:** sólo datos (parámetros). **Cohesión:** un único propósito — dirigir el flujo.
