# Diagramas Nassi-Shneiderman

Diagramas del algoritmo **sin especificar lenguaje**: son la plantilla única para C, Pascal y Fortran. Hay **un diagrama por módulo** de [`../algoritmo.md`](../algoritmo.md) y cada programa tiene un procedimiento/función por diagrama, con el mismo nombre y parámetros.

Cada módulo está en dos formatos con **el mismo contenido**:

- `ns-*.md`: diagrama en texto (revisión rápida en GitHub).
- `structorizer/*.nsd`: código de [Structorizer](https://structorizer.fisch.lu) (abrir con *Archivo → Abrir*; exportar PNG/SVG/PDF desde ahí).

| Módulo | Diagrama | Structorizer |
|--------|----------|--------------|
| Constantes y registros | — (ver `algoritmo.md`) | [`tipos_y_constantes.nsd`](structorizer/tipos_y_constantes.nsd) |
| Programa principal | [`ns-main.md`](ns-main.md) | [`main.nsd`](structorizer/main.nsd) |
| `leer_entrada` | [`ns-leer-entrada.md`](ns-leer-entrada.md) | [`leer_entrada.nsd`](structorizer/leer_entrada.nsd) |
| `peso_total` | [`ns-peso-total.md`](ns-peso-total.md) | [`peso_total.nsd`](structorizer/peso_total.nsd) |
| `f_velocidad` | [`ns-f-velocidad.md`](ns-f-velocidad.md) | [`f_velocidad.nsd`](structorizer/f_velocidad.nsd) |
| `paso_rk4` | [`ns-paso-rk4.md`](ns-paso-rk4.md) | [`paso_rk4.nsd`](structorizer/paso_rk4.nsd) |
| `registrar_fila` | [`ns-registrar-fila.md`](ns-registrar-fila.md) | [`registrar_fila.nsd`](structorizer/registrar_fila.nsd) |
| `integrar_caida` | [`ns-integrar-caida.md`](ns-integrar-caida.md) | [`integrar_caida.nsd`](structorizer/integrar_caida.nsd) |
| `buscar_beta` | [`ns-buscar-beta.md`](ns-buscar-beta.md) | [`buscar_beta.nsd`](structorizer/buscar_beta.nsd) |
| `v_analitica` | [`ns-v-analitica.md`](ns-v-analitica.md) | [`v_analitica.nsd`](structorizer/v_analitica.nsd) |
| `x_analitica` | [`ns-x-analitica.md`](ns-x-analitica.md) | [`x_analitica.nsd`](structorizer/x_analitica.nsd) |
| `mostrar_tabla` | [`ns-mostrar-tabla.md`](ns-mostrar-tabla.md) | [`mostrar_tabla.nsd`](structorizer/mostrar_tabla.nsd) |
| `mostrar_salida` | [`ns-mostrar-salida.md`](ns-mostrar-salida.md) | [`mostrar_salida.nsd`](structorizer/mostrar_salida.nsd) |

## Convenciones

- `←` / `<-` asignación; `LEER` entrada; `ESCRIBIR` salida; `devolver` valor de una función (sólo como **última** instrucción).
- `MIENTRAS cond` repite mientras `cond` sea verdadera; `PARA k ← a HASTA b` ciclo con contador.
- Selección: triángulo con la condición, rama **V** (verdadero) a la izquierda y **F** a la derecha; `∅` = rama vacía.
- Parámetros de salida: se indican como “por referencia” en la tabla de cada diagrama (en C son punteros, en Pascal `var`, en Fortran `intent(out)`/`intent(inout)`).
- **Programación estructurada estricta**: sólo secuencia, selección e iteración; una entrada y una salida por módulo (sin `return`/`exit`/`break` intermedios).
- Los archivos `.nsd` declaran las palabras clave en español (`mientras`, `para … hasta`, `LEER`, `ESCRIBIR`, `devolver`) en sus atributos de raíz; los subprogramas incluyen `tipos_y_constantes`.

## Exportación para la entrega

Desde Structorizer: *Archivo → Exportar → Imagen (PNG/SVG)* con los nombres `ns-main.png`, `ns-leer-entrada.png`, etc.

## Criterio de revisión

Si se borran los nombres de lenguaje del código, cada procedimiento coincide línea a línea con su diagrama. Coupling sólo de datos (parámetros), sin variables globales modificables ni banderas de control; cada módulo con cohesión funcional.
