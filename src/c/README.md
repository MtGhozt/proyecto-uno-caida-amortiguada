# Implementación C (referencia)

Referencia estructurada del contrato para el equipo. Pascal y Fortran deben seguir el mismo diseño NS.

## Requisitos

- Compilador C11 (p. ej. `gcc`)

## Compilar y ejecutar

```bash
gcc -std=c11 -Wall -Wextra -O2 -o caida main.c -lm
./caida
```

En Windows (PowerShell):

```powershell
gcc -std=c11 -Wall -Wextra -O2 -o caida.exe main.c -lm
.\caida.exe
```

## Uso

1. Modo `1`: simular con \(\beta\) dado (pide masas, altura y \(\beta\)).
2. Modo `2`: buscar \(\beta\) para aterrizar ≈ 8 km/h (pide masas y altura).

Caso del enunciado (modo 2): masas `80`, `50`, altura `1500`.

## Contrato

Seguir [`docs/algoritmo.md`](../../docs/algoritmo.md) y los diagramas en [`docs/nassi-schneiderman/`](../../docs/nassi-schneiderman/).
