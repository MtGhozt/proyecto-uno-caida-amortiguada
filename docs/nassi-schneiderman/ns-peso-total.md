# NS — `peso_total`

Calcula el peso combinado \(W = (m_p + m_i)\,g\).

| | |
|---|---|
| **Entradas** | `masa_paracaidista`, `masa_impedimenta` (kg), `g` (m/s²) |
| **Salidas** | `W` (N) |
| **Llama a** | — |
| **Structorizer** | [`structorizer/peso_total.nsd`](structorizer/peso_total.nsd) |

Firma: `peso_total(masa_paracaidista: double, masa_impedimenta: double, g: double): double`

```text
┌────────────────────────────────────────────────────────────────────────┐
│ devolver (masa_paracaidista + masa_impedimenta) * g                    │
└────────────────────────────────────────────────────────────────────────┘
```

**Cohesión funcional**: una fórmula, sin E/S.
