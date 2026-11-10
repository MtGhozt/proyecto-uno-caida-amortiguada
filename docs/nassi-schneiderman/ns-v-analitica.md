# NS — `v_analitica`

Solución cerrada \(v(t) = \frac{W}{\beta}(1 - e^{-\beta g t / W})\) [Spiegel83], usada sólo para verificar el RK4.

| | |
|---|---|
| **Entradas** | `t`, `W`, `beta`, `g` |
| **Salidas** | \(v(t)\) (m/s) |
| **Llama a** | — |
| **Structorizer** | [`structorizer/v_analitica.nsd`](structorizer/v_analitica.nsd) |

Firma: `v_analitica(t: double, W: double, beta: double, g: double): double`

```text
┌────────────────────────────────────────────────────────────────────────┐
│ devolver (W / beta) * (1 - exp(-beta * g * t / W))                     │
└────────────────────────────────────────────────────────────────────────┘
```

Verificación; no interviene en la integración.
