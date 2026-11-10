# NS — `mostrar_tabla`

Imprime la tabla numérica \((t, v, x)\) junto a la solución analítica para verificar el RK4. Marca la fila de aterrizaje.

| | |
|---|---|
| **Entradas** | `r`, `W`, `beta`, `g` |
| **Salidas** | — (pantalla) |
| **Llama a** | `v_analitica`, `x_analitica` |
| **Structorizer** | [`structorizer/mostrar_tabla.nsd`](structorizer/mostrar_tabla.nsd) |

Firma: `mostrar_tabla(r: ResultadoCaida, W: double, beta: double, g: double)`

```text
┌────────────────────────────────────────────────────────────────────────┐
│ ESCRIBIR 't(s)', 'v(m/s)', 'x(m)', 'v_anal', 'x_anal'                  │
├────────────────────────────────────────────────────────────────────────┤
│ PARA k ← 1 HASTA r.n_filas                                             │
│   ┌────────────────────────────────────────────────────────────────────┤
│   │ ESCRIBIR r.filas[k].t, r.filas[k].v, r.filas[k].x,                 │
│   │          v_analitica(r.filas[k].t, W, beta, g),                    │
│   │          x_analitica(r.filas[k].t, W, beta, g)                     │
│   ├────────────────────────────────────────────────────────────────────┤
│   │╲                  r.aterrizo and (k = r.n_filas)                  ╱│
│   │ ╲ V                                                            F ╱ │
│   ├──────────────────────────────────────────────────┬─────────────────┤
│   │ ESCRIBIR '   [suelo]'                            │ ∅               │
│   ├──────────────────────────────────────────────────┴─────────────────┤
│   │ ESCRIBIR fin de línea                                              │
└───┴────────────────────────────────────────────────────────────────────┘
```

**No hace:** integrar ni modificar `r`.
