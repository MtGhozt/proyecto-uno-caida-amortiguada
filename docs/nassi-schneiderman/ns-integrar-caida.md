# NS — `integrar_caida`

Avanza el sistema con `paso_rk4` desde \(t=0, v=0, x=0\) hasta que \(x \ge H\). El último paso se **recorta** a \(h\cdot frac\) para estimar el instante y la velocidad de aterrizaje. Guarda la tabla (fila inicial, cada `IMPRIMIR_CADA` pasos y la de aterrizaje).

| | |
|---|---|
| **Entradas** | `W`, `beta`, `altura`, `g`, `h` |
| **Salidas** | `r: ResultadoCaida` (por referencia) |
| **Llama a** | `paso_rk4`, `registrar_fila` |
| **Structorizer** | [`structorizer/integrar_caida.nsd`](structorizer/integrar_caida.nsd) |

Firma: `integrar_caida(W: double, beta: double, altura: double, g: double, h: double, r: ResultadoCaida)`

```text
┌────────────────────────────────────────────────────────────────────────────────┐
│ t ← 0                                                                          │
│ v ← 0                                                                          │
│ x ← 0                                                                          │
│ i ← 0                                                                          │
│ aterrizo ← false                                                               │
│ r.n_filas ← 0                                                                  │
├────────────────────────────────────────────────────────────────────────────────┤
│ registrar_fila(r, t, v, x)                                                     │
├────────────────────────────────────────────────────────────────────────────────┤
│ MIENTRAS not aterrizo and (i < MAX_PASOS)                                      │
│   ┌────────────────────────────────────────────────────────────────────────────┤
│   │ paso_rk4(h, v, x, g, beta, W, v_sig, x_sig)                                │
│   ├────────────────────────────────────────────────────────────────────────────┤
│   │╲                              x_sig ≥ altura                              ╱│
│   │ ╲ V                                                                    F ╱ │
│   ├────────────────────────────────────────────────────────┬───────────────────┤
│   │ frac ← (altura - x) / (x_sig - x)                      │ t ← t + h         │
│   ├────────────────────────────────────────────────────────┤                   │
│   │ paso_rk4(h * frac, v, x, g, beta, W, v_sig, x_sig)     │                   │
│   ├────────────────────────────────────────────────────────┤                   │
│   │ t ← t + h * frac                                       │                   │
│   │ aterrizo ← true                                        │                   │
│   ├────────────────────────────────────────────────────────┴───────────────────┤
│   │ v ← v_sig                                                                  │
│   │ x ← x_sig                                                                  │
│   │ i ← i + 1                                                                  │
│   ├────────────────────────────────────────────────────────────────────────────┤
│   │╲                  aterrizo or (i mod IMPRIMIR_CADA = 0)                   ╱│
│   │ ╲ V                                                                    F ╱ │
│   ├────────────────────────────────────────────────────────┬───────────────────┤
│   │ registrar_fila(r, t, v, x)                             │ ∅                 │
├───┴────────────────────────────────────────────────────────┴───────────────────┤
│ r.aterrizo ← aterrizo                                                          │
│ r.t_suelo ← t                                                                  │
│ r.v_suelo ← v                                                                  │
│ r.x_suelo ← x                                                                  │
│ r.pasos ← i                                                                    │
└────────────────────────────────────────────────────────────────────────────────┘
```

**No hace:** E/S, ni buscar \(\beta\). Siempre guarda la tabla, así no necesita una bandera `verbose` (se evita el acoplamiento de control). Si no aterriza en `MAX_PASOS`, `r.aterrizo` es falso y `r` contiene el último estado.
