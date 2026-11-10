# NS — `registrar_fila`

Agrega la fila \((t, v, x)\) a la tabla del resultado (si hay capacidad).

| | |
|---|---|
| **Entradas** | `r` (por referencia), `t`, `v`, `x` |
| **Salidas** | `r.n_filas`, `r.filas` actualizados |
| **Llama a** | — |
| **Structorizer** | [`structorizer/registrar_fila.nsd`](structorizer/registrar_fila.nsd) |

Firma: `registrar_fila(r: ResultadoCaida, t: double, v: double, x: double)`

```text
┌────────────────────────────────────────────────────────────────────────┐
│╲                        r.n_filas < MAX_FILAS                         ╱│
│ ╲ V                                                                F ╱ │
├─────────────────────────────────────────────────────┬──────────────────┤
│ r.n_filas ← r.n_filas + 1                           │ ∅                │
│ r.filas[r.n_filas].t ← t                            │                  │
│ r.filas[r.n_filas].v ← v                            │                  │
│ r.filas[r.n_filas].x ← x                            │                  │
└─────────────────────────────────────────────────────┴──────────────────┘
```

Por construcción la capacidad `MAX_FILAS = MAX_PASOS/IMPRIMIR_CADA + 2` nunca se excede; la condición es defensiva. (Índices base 1 en el diagrama; C usa base 0.)
