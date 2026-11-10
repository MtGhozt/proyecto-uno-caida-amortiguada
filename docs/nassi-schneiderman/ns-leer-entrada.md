# NS — `leer_entrada`

Lee y valida. No calcula física.

```
┌─────────────────────────────────────────┐
│ Pedir modo (1 o 2)                      │
├───────────────┬─────────────────────────┤
│ modo inválido │ modo ok                 │
│ → fallar      │ Pedir masa_paracaidista │
│               │ (> 0)                   │
│               │ Pedir masa_impedimenta  │
│               │ (≥ 0)                   │
│               │ Pedir altura (> 0)      │
│               ├──────────┬──────────────┤
│               │ modo = 1 │ modo = 2     │
│               │ Pedir    │ beta ← n/a   │
│               │ beta > 0 │              │
│               └──────────┴──────────────┘
│               Devolver éxito + Entrada  │
└─────────────────────────────────────────┘
```

**No hace:** peso, RK4, búsqueda de \(\beta\).
