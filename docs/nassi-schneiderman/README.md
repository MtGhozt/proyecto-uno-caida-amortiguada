# Diagramas Nassi-Shneiderman

Aquí van los diagramas del algoritmo **sin especificar lenguaje**.

## Estado actual (borrador para revisión del equipo)

Borradores en Markdown (cajas NS en texto). Sirven para validar **cohesión** y **coupling** antes de exportar PNG/SVG desde Dia, Structorizer o draw.io.

| Archivo | Módulo |
|---------|--------|
| [`ns-main.md`](ns-main.md) | Programa principal |
| [`ns-leer-entrada.md`](ns-leer-entrada.md) | Entrada / validación |
| [`ns-paso-rk4.md`](ns-paso-rk4.md) | Paso RK4 escalar |
| [`ns-integrar-caida.md`](ns-integrar-caida.md) | Integración hasta el suelo |
| [`ns-buscar-beta.md`](ns-buscar-beta.md) | Bisección de \(\beta\) |
| [`ns-mostrar-salida.md`](ns-mostrar-salida.md) | Salida |

Módulos auxiliares del contrato (sin diagrama aparte por simplicidad; aparecen dentro de los anteriores):

- `peso_total`, `f_velocidad`, `v_analitica`, `x_analitica`

## Qué entregar (versión final del curso)

- Los mismos diagramas exportados como PDF, PNG o SVG.
- Convención de nombres al exportar:

```
ns-main.png
ns-leer-entrada.png
ns-paso-rk4.png
ns-integrar-caida.png
ns-buscar-beta.png
ns-mostrar-salida.png
```

## Criterio de revisión

Si se borran nombres de lenguaje, el diagrama sigue siendo la **plantilla única** para C, Pascal y Fortran.  
Persona diseño lidera; el resto revisa coupling y cohesión contra [`../algoritmo.md`](../algoritmo.md).
