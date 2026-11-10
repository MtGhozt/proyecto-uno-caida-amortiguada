# NS — `leer_entrada`

Pide y valida el modo, los tres parámetros del usuario y, en modo 1, \(\beta\). No calcula física. Una sola salida: los bloques siguientes se ejecutan sólo mientras `ok` siga verdadero.

| | |
|---|---|
| **Entradas** | — (teclado) |
| **Salidas** | `e: Entrada` (por referencia), `ok: lógico` (por referencia) |
| **Llama a** | — |
| **Structorizer** | [`structorizer/leer_entrada.nsd`](structorizer/leer_entrada.nsd) |

Firma: `leer_entrada(e: Entrada, ok: boolean)`

```text
┌────────────────────────────────────────────────────────────────────────┐
│ campo ← 'modo'                                                         │
│ ESCRIBIR 'Modo (1=simular con beta, 2=buscar beta): '                  │
│ LEER e.modo                                                            │
│ ok ← (e.modo = 1) or (e.modo = 2)                                      │
│ e.beta ← 0                                                             │
├────────────────────────────────────────────────────────────────────────┤
│╲                                  ok                                  ╱│
│ ╲ V                                                                F ╱ │
├─────────────────────────────────────────────────────┬──────────────────┤
│ campo ← 'masa del paracaidista'                     │ ∅                │
│ ESCRIBIR 'Masa paracaidista (kg): '                 │                  │
│ LEER e.masa_paracaidista                            │                  │
│ ok ← e.masa_paracaidista > 0                        │                  │
├─────────────────────────────────────────────────────┴──────────────────┤
│╲                                  ok                                  ╱│
│ ╲ V                                                                F ╱ │
├─────────────────────────────────────────────────────┬──────────────────┤
│ campo ← 'masa de la impedimenta'                    │ ∅                │
│ ESCRIBIR 'Masa impedimenta (kg): '                  │                  │
│ LEER e.masa_impedimenta                             │                  │
│ ok ← e.masa_impedimenta ≥ 0                         │                  │
├─────────────────────────────────────────────────────┴──────────────────┤
│╲                                  ok                                  ╱│
│ ╲ V                                                                F ╱ │
├─────────────────────────────────────────────────────┬──────────────────┤
│ campo ← 'altura'                                    │ ∅                │
│ ESCRIBIR 'Altura de salto (m): '                    │                  │
│ LEER e.altura                                       │                  │
│ ok ← e.altura > 0                                   │                  │
├─────────────────────────────────────────────────────┴──────────────────┤
│╲                         ok and (e.modo = 1)                          ╱│
│ ╲ V                                                                F ╱ │
├─────────────────────────────────────────────────────┬──────────────────┤
│ campo ← 'beta'                                      │ ∅                │
│ ESCRIBIR 'Beta (N*s/m): '                           │                  │
│ LEER e.beta                                         │                  │
│ ok ← e.beta > 0                                     │                  │
├─────────────────────────────────────────────────────┴──────────────────┤
│╲                                not ok                                ╱│
│ ╲ V                                                                F ╱ │
├─────────────────────────────────────────────────────┬──────────────────┤
│ ESCRIBIR 'Valor inválido: ', campo                  │ ∅                │
└─────────────────────────────────────────────────────┴──────────────────┘
```

**No hace:** peso, RK4, búsqueda de \(\beta\).
