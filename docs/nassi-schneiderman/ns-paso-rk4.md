# NS — `paso_rk4`

Un paso de Runge-Kutta de 4.º orden [Burden85, p. 248] para el sistema acoplado \(v' = f(v)\), \(x' = v\). Las pendientes de \(x\) usan las velocidades intermedias del RK4 de \(v\).

| | |
|---|---|
| **Entradas** | `h` (s), `v`, `x` (estado actual), `g`, `beta`, `W` (parámetros de \(f\)) |
| **Salidas** | `v_sig`, `x_sig` (por referencia) |
| **Llama a** | `f_velocidad` |
| **Structorizer** | [`structorizer/paso_rk4.nsd`](structorizer/paso_rk4.nsd) |

Firma: `paso_rk4(h: double, v: double, x: double, g: double, beta: double, W: double, v_sig: double, x_sig: double)`

```text
┌────────────────────────────────────────────────────────────────────────┐
│ k1v ← h * f_velocidad(v, g, beta, W)                                   │
│ k1x ← h * v                                                            │
├────────────────────────────────────────────────────────────────────────┤
│ k2v ← h * f_velocidad(v + k1v / 2, g, beta, W)                         │
│ k2x ← h * (v + k1v / 2)                                                │
├────────────────────────────────────────────────────────────────────────┤
│ k3v ← h * f_velocidad(v + k2v / 2, g, beta, W)                         │
│ k3x ← h * (v + k2v / 2)                                                │
├────────────────────────────────────────────────────────────────────────┤
│ k4v ← h * f_velocidad(v + k3v, g, beta, W)                             │
│ k4x ← h * (v + k3v)                                                    │
├────────────────────────────────────────────────────────────────────────┤
│ v_sig ← v + (k1v + 2 * k2v + 2 * k3v + k4v) / 6                        │
│ x_sig ← x + (k1x + 2 * k2x + 2 * k3x + k4x) / 6                        │
└────────────────────────────────────────────────────────────────────────┘
```

**Cohesión:** sólo el esquema numérico. **No hace:** E/S ni decide cuándo parar.
