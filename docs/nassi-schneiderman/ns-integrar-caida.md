# NS — `integrar_caida`

Avanza el sistema \(v'=f(t,v)\), \(x'=v\) con RK4 acoplado hasta \(x \ge H\).

**Entrada:** \(W\), \(\beta\), altura \(H\), \(g\), \(h\), bandera `verbose`.  
**Salida:** `ResultadoCaida` (\(t_{\mathrm{suelo}}, v_{\mathrm{suelo}}, x_{\mathrm{suelo}}\), pasos).

```
┌────────────────────────────────────────────────────────────┐
│ t ← 0; v ← 0; x ← 0                                        │
│ si verbose: imprimir encabezado y fila t=0                 │
│ (opcional: columnas v_analítica, x_analítica)              │
├────────────────────────────────────────────────────────────┤
│ REPETIR                                                    │
│   calcular (v_next, x_next) con un paso RK4 de sistema     │
│   ┌─────────────────────┬────────────────────────────────┐ │
│   │ x_next ≥ H          │ x_next < H                     │ │
│   │ frac ← (H-x)/(x_next-x)                              │ │
│   │ h_uso ← h · frac                                     │ │
│   │ rehacer paso con h_uso → v_suelo, t_suelo            │ │
│   │ si verbose: fila final “suelo”                       │ │
│   │ devolver éxito                                       │ │
│   │                     │ t ← t+h; v ← v_next; x ← x_next│ │
│   │                     │ si verbose y toca imprimir:    │ │
│   │                     │   fila intermedia              │ │
│   └─────────────────────┴────────────────────────────────┘ │
│ HASTA agotar max_pasos → fallar / devolver estado actual   │
└────────────────────────────────────────────────────────────┘
```

**Usa:** `f_velocidad` (y opcionalmente `v_analitica` / `x_analitica` solo para tabla).  
**No hace:** leer del usuario ni buscar \(\beta\).

Nota: el paso de sistema acoplado es interno a este módulo; `paso_rk4` escalar sigue existiendo como pieza reutilizable del contrato.
