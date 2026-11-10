# NS — `mostrar_salida`

Imprime el resumen de resultados. El texto de \(\beta\) depende de `e.modo` (dato de la entrada, no una bandera extra).

| | |
|---|---|
| **Entradas** | `e`, `W`, `beta`, `r`, `h`, `v_meta` |
| **Salidas** | — (pantalla) |
| **Llama a** | — |
| **Structorizer** | [`structorizer/mostrar_salida.nsd`](structorizer/mostrar_salida.nsd) |

Firma: `mostrar_salida(e: Entrada, W: double, beta: double, r: ResultadoCaida, h: double, v_meta: double)`

```text
┌──────────────────────────────────────────────────────────────────────────────┐
│ ESCRIBIR '=== Resultado ==='                                                 │
│ ESCRIBIR 'masas: ', e.masa_paracaidista, ' + ', e.masa_impedimenta,          │
│          ' kg | W = ', W, ' N | H = ', e.altura, ' m'                        │
├──────────────────────────────────────────────────────────────────────────────┤
│╲                                 e.modo = 2                                 ╱│
│ ╲ V                                                                      F ╱ │
├────────────────────────────────────────────────┬─────────────────────────────┤
│ ESCRIBIR 'beta encontrado: ', beta, ' N*s/m'   │ ESCRIBIR 'beta usado: ',    │
│ ESCRIBIR 'v_meta: ', v_meta, ' m/s (',         │          beta, ' N*s/m'     │
│          v_meta * 3.6, ' km/h)'                │                             │
├────────────────────────────────────────────────┴─────────────────────────────┤
│ ESCRIBIR 't_suelo: ', r.t_suelo, ' s'                                        │
│ ESCRIBIR 'x_suelo: ', r.x_suelo, ' m'                                        │
│ ESCRIBIR 'v_suelo: ', r.v_suelo, ' m/s (', r.v_suelo * 3.6, ' km/h)'         │
│ ESCRIBIR 'pasos RK4: ', r.pasos, ' (h = ', h, ' s)'                          │
└──────────────────────────────────────────────────────────────────────────────┘
```

**No hace:** integrar, buscar \(\beta\) ni validar entrada (la conversión ×3.6 a km/h es sólo de formato).
