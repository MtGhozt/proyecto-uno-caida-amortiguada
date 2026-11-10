# NS — `f_velocidad`

Lado derecho de la EDO \(dv/dt = g - (\beta g / W)\,v\). Es el **único** módulo que conoce el modelo de fuerzas. La EDO es autónoma, por eso no recibe \(t\).

| | |
|---|---|
| **Entradas** | `v` (m/s), `g`, `beta` (N·s/m), `W` (N) |
| **Salidas** | \(dv/dt\) (m/s²) |
| **Llama a** | — |
| **Structorizer** | [`structorizer/f_velocidad.nsd`](structorizer/f_velocidad.nsd) |

Firma: `f_velocidad(v: double, g: double, beta: double, W: double): double`

```text
┌────────────────────────────────────────────────────────────────────────┐
│ devolver g - (beta * g / W) * v                                        │
└────────────────────────────────────────────────────────────────────────┘
```

**Coupling:** sólo datos. Cambiar el modelo de resistencia sólo toca este módulo.
