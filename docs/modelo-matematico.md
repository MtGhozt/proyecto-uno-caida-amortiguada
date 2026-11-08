# Modelo matemático — Caída amortiguada

## Unidades y constantes

| Magnitud | Símbolo | Unidad SI sugerida |
|----------|---------|--------------------|
| Peso total | \(W\) | N (o kgf si el enunciado trata “peso” como masa×g; ver nota) |
| Masa total | \(m\) | kg |
| Gravedad | \(g\) | \(9.81\,\mathrm{m/s^2}\) |
| Velocidad | \(v\) | m/s (positiva hacia abajo) |
| Distancia | \(x\) | m (positiva hacia abajo, origen en el salto) |
| Constante de resistencia | \(\beta\) | N·s/m (si \(R=\beta v\) y fuerzas en newtons) |
| Tiempo | \(t\) | s |
| Altura de salto | \(H\) | m |

**Nota práctica del enunciado:** el texto usa “peso” en kg (80 kg + 50 kg). En la implementación conviene tratar esos valores como **masas** \(m_p\) y \(m_i\), definir \(m = m_p + m_i\) y \(W = mg\), y trabajar todo en SI.

**Conversión de la meta de aterrizaje:**

\[
8\,\mathrm{km/h} = 8 \cdot \frac{1000}{3600} = \frac{20}{9} \approx 2.222\,\mathrm{m/s}
\]

## EDO de la velocidad

\[
\frac{dv}{dt} = g\left(1 - \frac{\beta}{W}v\right) = g - \frac{\beta g}{W}v,
\quad v(0)=0
\]

En forma RK4: \(y' = f(t,y)\) con \(y=v\) y

\[
f(t,v) = g - \frac{\beta g}{W}v
\]

(no depende explícitamente de \(t\)).

## Solución analítica (verificación)

\[
v(t)=\frac{W}{\beta}\left(1-e^{-\beta g t/W}\right)
\]

\[
x(t)=\frac{W}{\beta}t+\frac{W}{\beta g}e^{-\beta g t/W}-\frac{W}{\beta g}
\]

Velocidad límite: \(v_\infty = W/\beta\).

## Distancia y tiempo de llegada al suelo

Se integra hasta que \(x(t) \approx H\) (altura de salto). Opciones:

1. Integrar \(v\) con RK4 y, en cada paso, integrar también \(x'=v\) (sistema o segundo RK4).
2. Avanzar en el tiempo hasta cruzar \(x=H\) y interpolar el último intervalo.

La velocidad de aterrizaje es \(v\) en ese instante.

## Pregunta de investigación (\(\beta\))

Datos fijos del experimento:

- \(H = 1500\,\mathrm{m}\)
- \(m_p = 80\,\mathrm{kg}\), \(m_i = 50\,\mathrm{kg}\) → \(m=130\,\mathrm{kg}\)
- Meta: \(v(H) \approx 2.222\,\mathrm{m/s}\)

Buscar \(\beta > 0\) (p. ej. **bisección** o búsqueda por intervalos) tal que la velocidad al suelo quede dentro de una tolerancia acordada (sugerida: \(\pm 0.05\,\mathrm{m/s}\) o \(\pm 0.2\,\mathrm{km/h}\)).

## Runge-Kutta 4 (recordatorio)

\[
\begin{aligned}
k_1 &= h f(t_i, w_i)\\
k_2 &= h f(t_i+h/2, w_i+k_1/2)\\
k_3 &= h f(t_i+h/2, w_i+k_2/2)\\
k_4 &= h f(t_i+h, w_i+k_3)\\
w_{i+1} &= w_i + (k_1+2k_2+2k_3+k_4)/6
\end{aligned}
\]
