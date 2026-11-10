# Proyecto uno — Caída amortiguada

Repositorio del **Proyecto programado 1** (IC4700 Lenguajes de Programación): diseño estructurado de un algoritmo numérico (Runge-Kutta 4) para la caída amortiguada de un paracaidista, implementado en **C**, **Pascal** y **Fortran**.

Equipo de **4 personas**. Repo privado: [MtGhozt/proyecto-uno-caida-amortiguada](https://github.com/MtGhozt/proyecto-uno-caida-amortiguada).

## De qué trata

Un paracaidista cae desde el reposo con resistencia del aire \(R = \beta v\). Hay que:

1. Modelar la EDO y conocer la solución analítica (verificación).
2. Resolver numéricamente con **RK4**.
3. Implementar el **mismo** algoritmo en **C, Pascal y Fortran**.
4. Hallar experimentalmente \(\beta\) para: altura **1500 m**, masas **80 kg + 50 kg**, velocidad al suelo ≈ **8 km/h**.
5. Entregar diagramas **Nassi-Shneiderman** (plantilla única) con buen coupling y cohesión.

Enunciado completo en Markdown: [`docs/enunciado.md`](docs/enunciado.md).

## Estructura

```
docs/
  enunciado.md              # enunciado en Markdown
  modelo-matematico.md      # EDO, analítica, RK4, unidades
  algoritmo.md              # contrato compartido (fuente de verdad)
  equipo.md                 # Persona 1–4
  nassi-schneiderman/       # diagramas NS
  assets/                   # figuras del enunciado
  original/                 # .docx original
src/
  c/                        # implementación C
  pascal/                   # implementación Pascal
  fortran/                  # implementación Fortran
CONTRIBUTING.md
README.md
```

## Cómo empezar (equipo)

1. Leer [`docs/enunciado.md`](docs/enunciado.md) y [`docs/modelo-matematico.md`](docs/modelo-matematico.md).
2. Asignar nombres en [`docs/equipo.md`](docs/equipo.md).
3. Revisar y confirmar el paquete: [`docs/revision-grupo.md`](docs/revision-grupo.md) (contrato + NS + C/Pascal/Fortran).
4. Validar las tres versiones con la misma entrada y contra la solución analítica.
5. Exportar diagramas NS a PNG/SVG para la entrega.

## Roles sugeridos (Persona 1–4)

| Persona | Enfoque |
|---------|---------|
| 1 | Diagramas NS + contrato |
| 2 | C + verificación analítica |
| 3 | Pascal |
| 4 | Fortran + búsqueda de \(\beta\) |

## Compilación (cuando exista implementación)

```bash
# C
gcc -std=c11 -Wall -Wextra -O2 -o caida src/c/main.c -lm

# Pascal (Free Pascal)
fpc src/pascal/main.pas

# Fortran
gfortran -Wall -O2 -o caida src/fortran/main.f90
```

## Documentación clave

- [`docs/enunciado.md`](docs/enunciado.md)
- [`docs/modelo-matematico.md`](docs/modelo-matematico.md)
- [`docs/algoritmo.md`](docs/algoritmo.md)
- [`docs/equipo.md`](docs/equipo.md)
- [`CONTRIBUTING.md`](CONTRIBUTING.md)
