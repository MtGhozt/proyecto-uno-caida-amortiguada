# NS — `paso_rk4` (escalar genérico)

Un paso Runge-Kutta 4 para \(w' = f(t,w)\). No conoce el modelo de caída.

**Entrada:** función \(f\), paso \(h\), \(t\), \(w\), y parámetros que \(f\) necesite (p. ej. \(g,\beta,W\)).  
**Salida:** \(w_{i+1}\).

```
┌──────────────────────────────────────────┐
│ k1 ← h · f(t, w)                         │
│ k2 ← h · f(t+h/2, w+k1/2)                │
│ k3 ← h · f(t+h/2, w+k2/2)                │
│ k4 ← h · f(t+h, w+k3)                    │
│ devolver w + (k1 + 2k2 + 2k3 + k4) / 6   │
└──────────────────────────────────────────┘
```

**Cohesión:** solo el esquema numérico.  
**Coupling:** recibe \(f\) / parámetros; no imprime ni lee I/O.
