# Implementación Fortran

Misma estructura que la referencia C / contrato NS.

## Requisitos

- `gfortran` (GCC)

## Compilar y ejecutar

```bash
gfortran -Wall -O2 -o caida main.f90
./caida
```

En Windows (PowerShell):

```powershell
gfortran -Wall -O2 -o caida.exe main.f90
.\caida.exe
```

## Uso

Igual que C: modo `1` (beta dado) o `2` (buscar beta). Caso enunciado: `2` / `80` / `50` / `1500`.

## Contrato

[`docs/algoritmo.md`](../../docs/algoritmo.md) y [`docs/nassi-schneiderman/`](../../docs/nassi-schneiderman/).
