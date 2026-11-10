# Paquete de revisión — Contrato + NS + C/Pascal/Fortran

Para el equipo: revisar y **confirmar** diseño + las tres implementaciones.

## Qué mirar

| Pieza | Ruta | Pregunta |
|-------|------|----------|
| Contrato congelado | [`algoritmo.md`](algoritmo.md) | ¿Defaults (`h`, `tol_v`, bisección) y módulos OK? |
| Borradores NS | [`nassi-schneiderman/`](nassi-schneiderman/) | ¿Cohesión / coupling claros? ¿Falta algún módulo? |
| C | [`../src/c/main.c`](../src/c/main.c) | ¿Sigue el contrato y el NS? |
| Pascal | [`../src/pascal/main.pas`](../src/pascal/main.pas) | ¿Mismo flujo/módulos que C? |
| Fortran | [`../src/fortran/main.f90`](../src/fortran/main.f90) | ¿Mismo flujo/módulos que C? |

## Build

```powershell
# C
cd src/c
gcc -std=c11 -Wall -Wextra -O2 -o caida.exe main.c -lm

# Pascal (Free Pascal)
cd ..\pascal
fpc -O2 main.pas

# Fortran
cd ..\fortran
gfortran -std=f2008 -Wall -O2 -o caida.exe main.f90
```

## Corrida ejemplo (modo investigación)

Entrada (igual en los tres):

```
2
80
50
1500
```

Resultado esperado (calculado con el algoritmo corregido; las tres versiones deben coincidir):

| Magnitud | Valor |
|----------|-------|
| \(W\) | 1275.3 N |
| \(\beta\) encontrado | ≈ 569.53 N·s/m (5 iteraciones de bisección en [1, 2600]) |
| \(v_{\mathrm{meta}}\) | 2.222… m/s (8 km/h) |
| \(v_{\mathrm{suelo}}\) | ≈ 2.2392 m/s (≈ 8.061 km/h) |
| \(t_{\mathrm{suelo}}\) | ≈ 670.11 s (6702 pasos) |
| Dentro de `tol_v=0.05` | sí |

La tabla imprime columnas analíticas para verificar el RK4.

## Decisión pedida al grupo

Responder explícitamente:

1. **OK** al contrato (defaults + lista de módulos), o qué cambiar.
2. **OK** a los borradores NS (o ajustes de acoplamiento/cohesión).
3. **OK** a que C/Pascal/Fortran reflejan el mismo diseño (o listar divergencias).
4. Siguiente paso tras OK: exportar NS a PNG/SVG y validación cruzada formal.

## Fuera de esta revisión

- PNG/SVG finales de NS (los `.md` son el borrador revisable).
- Asignación definitiva de nombres en [`equipo.md`](equipo.md).
