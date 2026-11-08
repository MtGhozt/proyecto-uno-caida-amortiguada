# Contrato del algoritmo (compartido)

Este documento es la **fuente de verdad** para las tres implementaciones (C, Pascal, Fortran). Los diagramas Nassi-Shneiderman deben reflejar exactamente esta descomposición.

## Entrada (obligatoria)

| Parámetro | Nombre sugerido | Unidad |
|-----------|-----------------|--------|
| Peso/masa del paracaidista | `masa_paracaidista` | kg |
| Peso/masa de la impedimenta | `masa_impedimenta` | kg |
| Altura de salto | `altura` | m |

Parámetros internos / configurables (mismos defaults en los 3 lenguajes):

| Parámetro | Default sugerido | Notas |
|-----------|------------------|-------|
| `g` | 9.81 | m/s² |
| `beta` | entrada adicional o modo búsqueda | N·s/m (si \(W=mg\)) |
| `N` o `h` | acordar en el diseño NS | pasos / tamaño de paso RK4 |
| `v_meta` | 8 km/h → 20/9 m/s | solo modo investigación |

## Salida mínima

1. Tabla o secuencia de \(t_i, v_i, x_i\) (o al menos \(v\) y \(x\) hasta el suelo).
2. Velocidad al llegar al suelo (m/s y, opcional, km/h).
3. En modo investigación: valor de \(\beta\) encontrado.

## Módulos sugeridos (bajo coupling, alta cohesión)

Cada módulo hace **una** cosa. Comunicación preferible por parámetros (no variables globales).

| Módulo | Responsabilidad | No debe hacer |
|--------|-----------------|---------------|
| `leer_entrada` | Leer y validar los 3 parámetros del usuario | calcular física |
| `peso_total` | \(W = (m_p+m_i)\,g\) | integrar |
| `f_velocidad` | \(f(t,v)=g-(\beta g/W)v\) | I/O |
| `paso_rk4` | Un paso RK4 genérico dados \(f,h,t,w\) | conocer el modelo |
| `integrar_caida` | Avanzar hasta \(x \approx H\) usando RK4 | pedir datos al usuario |
| `v_analitica` / `x_analitica` | Verificación opcional | I/O pesado |
| `buscar_beta` | Bisección/u otra búsqueda de \(\beta\) | reinventar RK4 (llama a `integrar_caida`) |
| `mostrar_salida` | Imprimir resultados | calcular |

## Flujo principal

1. Leer entrada.
2. Calcular \(W\).
3. Si modo normal: pedir/usar \(\beta\), integrar, mostrar.
4. Si modo investigación: buscar \(\beta\) hasta cumplir \(v_{\mathrm{suelo}} \approx v_{\mathrm{meta}}\), mostrar \(\beta\) y verificación.

## Criterios de calidad (evaluación del curso)

- **Cohesión (binding):** cada procedimiento con un propósito claro.
- **Coupling:** mínimo; preferir paso de parámetros; evitar estado global compartido entre módulos.
- Las tres versiones deben seguir el **mismo** diagrama NS.

## Estado

- [ ] Diagramas NS aprobados por el equipo (`docs/nassi-schneiderman/`)
- [ ] Defaults de `N`/`h` y tolerancia de \(\beta` congelados
- [ ] Implementación C alineada
- [ ] Implementación Pascal alineada
- [ ] Implementación Fortran alineada
- [ ] Validación cruzada (mismos inputs → mismas salidas)
