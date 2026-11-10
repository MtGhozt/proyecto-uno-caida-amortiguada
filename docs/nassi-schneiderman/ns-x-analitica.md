# NS — `x_analitica`

Solución cerrada \(x(t) = \frac{W}{\beta}t + \frac{W}{\beta g}e^{-\beta g t/W} - \frac{W}{\beta g}\) [Spiegel83], usada sólo para verificar el RK4.

| | |
|---|---|
| **Entradas** | `t`, `W`, `beta`, `g` |
| **Salidas** | \(x(t)\) (m) |
| **Llama a** | — |
| **Structorizer** | [`structorizer/x_analitica.nsd`](structorizer/x_analitica.nsd) |

Firma: `x_analitica(t: double, W: double, beta: double, g: double): double`

```text
┌────────────────────────────────────────────────────────────────────────┐
│ devolver (W / beta) * t + (W / (beta * g)) * exp(-beta * g * t / W)    │
│          - W / (beta * g)                                              │
└────────────────────────────────────────────────────────────────────────┘
```

Verificación; no interviene en la integración.
