# NS — `buscar_beta`

Bisección de \(\beta\) hasta \(|v_{\mathrm{suelo}} - v_{\mathrm{meta}}| \le tol_v\).

**Entrada:** \(W\), \(H\), \(g\), \(h\), \(v_{\mathrm{meta}}\), \(tol_v\).  
**Salida:** \(\beta\) y un `ResultadoCaida` de verificación (sin tabla verbose durante la búsqueda).

```
┌──────────────────────────────────────────────────────────┐
│ lo ← beta_lo; hi ← beta_hi                               │
│ v_lo ← v_suelo(lo); v_hi ← v_suelo(hi)                   │
│   (vía integrar_caida sin verbose)                       │
├───────────────┬──────────────────────────────────────────┤
│ sin cambio de │ hay cambio de signo respecto a v_meta    │
│ signo → fallar│                                          │
│               │ REPETIR hasta max_iter_beta              │
│               │   mid ← (lo+hi)/2                        │
│               │   v_mid ← v_suelo(mid)                   │
│               │   ┌──────────────┬─────────────────────┐ │
│               │   │ |v_mid-meta| │ v_mid > meta        │ │
│               │   │ ≤ tol_v      │ → lo ← mid          │ │
│               │   │ → éxito      │ (falta resistencia) │ │
│               │   │              │ else hi ← mid       │ │
│               │   └──────────────┴─────────────────────┘ │
│               │ devolver mid (éxito o mejor aprox.)      │
└───────────────┴──────────────────────────────────────────┘
```

**Coupling:** solo llama `integrar_caida` (o un helper que la use).  
**No reinventar** RK4 aquí.
