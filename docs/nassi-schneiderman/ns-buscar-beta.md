# NS — `buscar_beta`

Bisección de \(\beta\) hasta \(|v_{suelo}(\beta) - v_{meta}| \le tol_v\). Más \(\beta\) ⇒ más resistencia ⇒ menor \(v_{suelo}\). El extremo superior `hi = Z_ESTABLE·W/(g·h)` mantiene RK4 en su región de estabilidad para cualquier masa.

| | |
|---|---|
| **Entradas** | `W`, `altura`, `g`, `h`, `v_meta`, `tol_v` |
| **Salidas** | `beta`, `encontrado` (por referencia) |
| **Llama a** | `integrar_caida` |
| **Structorizer** | [`structorizer/buscar_beta.nsd`](structorizer/buscar_beta.nsd) |

Firma: `buscar_beta(W: double, altura: double, g: double, h: double, v_meta: double, tol_v: double, beta: double, encontrado: boolean)`

```text
┌────────────────────────────────────────────────────────────────────────────────────┐
│ lo ← BETA_LO                                                                       │
│ hi ← Z_ESTABLE * W / (g * h)                                                       │
├────────────────────────────────────────────────────────────────────────────────────┤
│ integrar_caida(W, lo, altura, g, h, r)                                             │
├────────────────────────────────────────────────────────────────────────────────────┤
│ v_lo ← r.v_suelo                                                                   │
├────────────────────────────────────────────────────────────────────────────────────┤
│ integrar_caida(W, hi, altura, g, h, r)                                             │
├────────────────────────────────────────────────────────────────────────────────────┤
│ v_hi ← r.v_suelo                                                                   │
│ encontrado ← false                                                                 │
│ iter ← 0                                                                           │
│ beta ← (lo + hi) / 2                                                               │
├────────────────────────────────────────────────────────────────────────────────────┤
│╲                      (v_lo - v_meta) * (v_hi - v_meta) ≤ 0                       ╱│
│ ╲ V                                                                            F ╱ │
├───────────────────────────────────────────────────────────────────────┬────────────┤
│ MIENTRAS not encontrado and (iter < MAX_ITER_BETA)                    │ ∅          │
│   ┌───────────────────────────────────────────────────────────────────┤            │
│   │ beta ← (lo + hi) / 2                                              │            │
│   ├───────────────────────────────────────────────────────────────────┤            │
│   │ integrar_caida(W, beta, altura, g, h, r)                          │            │
│   ├───────────────────────────────────────────────────────────────────┤            │
│   │╲                 abs(r.v_suelo - v_meta) ≤ tol_v                 ╱│            │
│   │ ╲ V                                                           F ╱ │            │
│   ├────────────────────┬──────────────────────────────────────────────┤            │
│   │ encontrado ← true  │╲             r.v_suelo > v_meta             ╱│            │
│   │                    │ ╲ V                                      F ╱ │            │
│   │                    ├───────────────────────┬──────────────────────┤            │
│   │                    │ lo ← beta             │ hi ← beta            │            │
│   ├────────────────────┴───────────────────────┴──────────────────────┤            │
│   │ iter ← iter + 1                                                   │            │
└───┴───────────────────────────────────────────────────────────────────┴────────────┘
```

**Coupling:** sólo llama a `integrar_caida` (no reimplementa RK4, no hace E/S). Si el intervalo no encierra la meta, devuelve `encontrado = falso` y el programa principal avisa.
