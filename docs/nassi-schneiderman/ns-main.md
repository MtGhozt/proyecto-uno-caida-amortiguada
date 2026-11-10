# NS — Programa principal (`main`)

Lenguaje-agnóstico. Orquesta módulos; no calcula física.

```
┌─────────────────────────────────────────────────────────┐
│ leer_entrada → Entrada e                                │
├─────────────────────────────────────────────────────────┤
│ W ← peso_total(e.masa_paracaidista,                     │
│                e.masa_impedimenta, g)                   │
├───────────────────────┬─────────────────────────────────┤
│ ¿e.modo = 1?          │ ¿e.modo = 2?                    │
│ (simular)             │ (buscar beta)                   │
├───────────────────────┼─────────────────────────────────┤
│ beta ← e.beta         │ ok ← buscar_beta(W, e.altura,   │
│ integrar_caida(…,     │   g, h, v_meta, tol_v,          │
│   verbose=sí, r)      │   → beta, r)                    │
│ mostrar_salida(…)     │ si ok:                          │
│                       │   integrar_caida(… verbose, r)  │
│                       │   mostrar_salida(…, modo=2)     │
│                       │ si no: error / mejor aprox.     │
└───────────────────────┴─────────────────────────────────┘
```

**Coupling:** solo llama módulos; no conoce la fórmula de \(f\) ni el detalle de RK4.  
**Cohesión:** un solo propósito — dirigir el flujo según el modo.
