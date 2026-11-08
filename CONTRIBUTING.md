# Cómo contribuir

## Flujo Git

1. Trabajar desde `main` actualizado.
2. Crear rama por área:
   - `feature/diseno-ns` — diagramas y contrato
   - `feature/c`
   - `feature/pascal`
   - `feature/fortran`
   - `docs/...` — solo documentación
3. Abrir Pull Request hacia `main`.
4. Al menos otra persona del equipo revisa antes de merge.

## Reglas

- No romper el contrato en [`docs/algoritmo.md`](docs/algoritmo.md) sin actualizarlo en el mismo PR.
- No subir binarios (`.exe`, `.o`, `.mod`, etc.); están en `.gitignore`.
- Commits claros y en español o inglés, pero consistentes (ej. `feat(c): paso RK4`).

## Prueba mínima antes de merge de código

Misma entrada de referencia (propuesta):

- masa paracaidista = 80
- masa impedimenta = 50
- altura = 1500
- un \(\beta\) de prueba fijo

Comparar \(v\) y \(x\) en algunos \(t\) entre lenguajes (tolerancia numérica razonable).
