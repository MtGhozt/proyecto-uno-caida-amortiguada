/*
 * Caída amortiguada — implementación C (referencia del contrato)
 * Seguir docs/algoritmo.md y docs/nassi-schneiderman/
 *
 * Build:
 *   gcc -std=c11 -Wall -Wextra -O2 -o caida main.c -lm
 */

#include <math.h>
#include <stdio.h>

#define G 9.81
#define H_PASO 0.1
#define V_META (20.0 / 9.0)
#define TOL_V 0.05
#define BETA_LO 1.0
#define BETA_HI 5000.0
#define MAX_ITER_BETA 60
#define IMPRIMIR_CADA 50
#define MAX_PASOS 200000

typedef struct {
    double masa_paracaidista;
    double masa_impedimenta;
    double altura;
    int modo; /* 1 = beta dado, 2 = buscar beta */
    double beta;
} Entrada;

typedef struct {
    double t_suelo;
    double v_suelo;
    double x_suelo;
    int pasos;
} ResultadoCaida;

static int leer_entrada(Entrada *e)
{
    printf("Modo (1=simular con beta, 2=buscar beta): ");
    if (scanf("%d", &e->modo) != 1 || (e->modo != 1 && e->modo != 2)) {
        fprintf(stderr, "Modo invalido.\n");
        return 0;
    }

    printf("Masa paracaidista (kg): ");
    if (scanf("%lf", &e->masa_paracaidista) != 1 || e->masa_paracaidista <= 0.0) {
        fprintf(stderr, "Masa paracaidista invalida.\n");
        return 0;
    }

    printf("Masa impedimenta (kg): ");
    if (scanf("%lf", &e->masa_impedimenta) != 1 || e->masa_impedimenta < 0.0) {
        fprintf(stderr, "Masa impedimenta invalida.\n");
        return 0;
    }

    printf("Altura de salto (m): ");
    if (scanf("%lf", &e->altura) != 1 || e->altura <= 0.0) {
        fprintf(stderr, "Altura invalida.\n");
        return 0;
    }

    e->beta = 0.0;
    if (e->modo == 1) {
        printf("Beta (N*s/m): ");
        if (scanf("%lf", &e->beta) != 1 || e->beta <= 0.0) {
            fprintf(stderr, "Beta invalida.\n");
            return 0;
        }
    }

    return 1;
}

static double peso_total(double masa_paracaidista, double masa_impedimenta, double g)
{
    return (masa_paracaidista + masa_impedimenta) * g;
}

/* f(t,v) = g - (beta*g/W)*v  (no depende de t) */
static double f_velocidad(double t, double v, double g, double beta, double W)
{
    (void)t;
    return g - (beta * g / W) * v;
}

/* Un paso RK4 escalar genérico: w' = f(t,w) */
static double paso_rk4(double (*f)(double, double, double, double, double),
                       double h, double t, double w,
                       double g, double beta, double W)
{
    double k1 = h * f(t, w, g, beta, W);
    double k2 = h * f(t + h / 2.0, w + k1 / 2.0, g, beta, W);
    double k3 = h * f(t + h / 2.0, w + k2 / 2.0, g, beta, W);
    double k4 = h * f(t + h, w + k3, g, beta, W);
    return w + (k1 + 2.0 * k2 + 2.0 * k3 + k4) / 6.0;
}

/*
 * Paso del sistema (v, x): v con paso_rk4; x con RK4 acoplado (x'=v).
 */
static void paso_sistema_rk4(double h, double t, double v, double x,
                             double g, double beta, double W,
                             double *v_out, double *x_out)
{
    double k1v = h * f_velocidad(t, v, g, beta, W);
    double k1x = h * v;

    double k2v = h * f_velocidad(t + h / 2.0, v + k1v / 2.0, g, beta, W);
    double k2x = h * (v + k1v / 2.0);

    double k3v = h * f_velocidad(t + h / 2.0, v + k2v / 2.0, g, beta, W);
    double k3x = h * (v + k2v / 2.0);

    double k4v = h * f_velocidad(t + h, v + k3v, g, beta, W);
    double k4x = h * (v + k3v);

    *v_out = paso_rk4(f_velocidad, h, t, v, g, beta, W);
    *x_out = x + (k1x + 2.0 * k2x + 2.0 * k3x + k4x) / 6.0;

    (void)k4v; /* k1v..k4v definen el mismo avance de v que paso_rk4 */
}

static double v_analitica(double t, double W, double beta, double g)
{
    return (W / beta) * (1.0 - exp(-beta * g * t / W));
}

static double x_analitica(double t, double W, double beta, double g)
{
    return (W / beta) * t
         + (W / (beta * g)) * exp(-beta * g * t / W)
         - (W / (beta * g));
}

static int integrar_caida(double W, double beta, double altura, double g, double h,
                          int verbose, ResultadoCaida *out)
{
    double t = 0.0;
    double v = 0.0;
    double x = 0.0;
    int i;

    if (verbose) {
        printf("\n%10s %12s %12s %12s %12s\n",
               "t(s)", "v(m/s)", "x(m)", "v_anal", "x_anal");
        printf("%10.2f %12.6f %12.6f %12.6f %12.6f\n",
               t, v, x,
               v_analitica(t, W, beta, g),
               x_analitica(t, W, beta, g));
    }

    for (i = 0; i < MAX_PASOS; i++) {
        double v_next;
        double x_next;

        paso_sistema_rk4(h, t, v, x, g, beta, W, &v_next, &x_next);

        if (x_next >= altura) {
            double frac;
            double t_s;
            double v_s;
            double x_s;

            if (fabs(x_next - x) < 1e-15) {
                frac = 0.0;
            } else {
                frac = (altura - x) / (x_next - x);
            }
            if (frac < 0.0) {
                frac = 0.0;
            }
            if (frac > 1.0) {
                frac = 1.0;
            }

            if (h * frac > 1e-15) {
                paso_sistema_rk4(h * frac, t, v, x, g, beta, W, &v_s, &x_s);
                t_s = t + h * frac;
            } else {
                v_s = v;
                x_s = x;
                t_s = t;
            }

            out->t_suelo = t_s;
            out->v_suelo = v_s;
            out->x_suelo = x_s;
            out->pasos = i + 1;

            if (verbose) {
                printf("%10.2f %12.6f %12.6f %12.6f %12.6f   <-- suelo\n",
                       out->t_suelo, out->v_suelo, out->x_suelo,
                       v_analitica(out->t_suelo, W, beta, g),
                       x_analitica(out->t_suelo, W, beta, g));
            }
            return 1;
        }

        t += h;
        v = v_next;
        x = x_next;

        if (verbose && ((i + 1) % IMPRIMIR_CADA == 0)) {
            printf("%10.2f %12.6f %12.6f %12.6f %12.6f\n",
                   t, v, x,
                   v_analitica(t, W, beta, g),
                   x_analitica(t, W, beta, g));
        }
    }

    out->t_suelo = t;
    out->v_suelo = v;
    out->x_suelo = x;
    out->pasos = MAX_PASOS;
    return 0;
}

static double velocidad_al_suelo(double W, double beta, double altura, double g, double h)
{
    ResultadoCaida r;
    integrar_caida(W, beta, altura, g, h, 0, &r);
    return r.v_suelo;
}

static int buscar_beta(double W, double altura, double g, double h,
                       double v_meta, double tol_v,
                       double *beta_out, ResultadoCaida *verif)
{
    double lo = BETA_LO;
    double hi = BETA_HI;
    double v_lo = velocidad_al_suelo(W, lo, altura, g, h);
    double v_hi = velocidad_al_suelo(W, hi, altura, g, h);
    int iter;

    /* Más beta => más resistencia => menor v al suelo */
    if ((v_lo - v_meta) * (v_hi - v_meta) > 0.0) {
        fprintf(stderr,
                "No hay cambio de signo en [%.1f, %.1f] "
                "(v_lo=%.4f, v_hi=%.4f, meta=%.4f).\n",
                lo, hi, v_lo, v_hi, v_meta);
        return 0;
    }

    for (iter = 0; iter < MAX_ITER_BETA; iter++) {
        double mid = 0.5 * (lo + hi);
        double v_mid = velocidad_al_suelo(W, mid, altura, g, h);

        if (fabs(v_mid - v_meta) <= tol_v) {
            *beta_out = mid;
            integrar_caida(W, mid, altura, g, h, 0, verif);
            return 1;
        }

        if (v_mid > v_meta) {
            lo = mid;
        } else {
            hi = mid;
        }
    }

    *beta_out = 0.5 * (lo + hi);
    integrar_caida(W, *beta_out, altura, g, h, 0, verif);
    return fabs(verif->v_suelo - v_meta) <= tol_v;
}

static void mostrar_salida(const Entrada *e, double W, double beta,
                           const ResultadoCaida *r, int modo_busqueda)
{
    double v_kmh = r->v_suelo * 3.6;

    printf("\n=== Resultado ===\n");
    printf("masas: %.2f + %.2f kg | W = %.4f N | H = %.2f m\n",
           e->masa_paracaidista, e->masa_impedimenta, W, e->altura);
    if (modo_busqueda) {
        printf("beta encontrado: %.6f N*s/m\n", beta);
        printf("v_meta: %.6f m/s (%.3f km/h)\n", V_META, V_META * 3.6);
    } else {
        printf("beta usado: %.6f N*s/m\n", beta);
    }
    printf("t_suelo: %.4f s\n", r->t_suelo);
    printf("x_suelo: %.6f m\n", r->x_suelo);
    printf("v_suelo: %.6f m/s (%.3f km/h)\n", r->v_suelo, v_kmh);
    printf("pasos RK4: %d (h=%.2f s)\n", r->pasos, H_PASO);
}

int main(void)
{
    Entrada e;
    ResultadoCaida r;
    double W;
    double beta = 0.0;

    printf("Proyecto uno: caida amortiguada (C)\n");
    if (!leer_entrada(&e)) {
        return 1;
    }

    W = peso_total(e.masa_paracaidista, e.masa_impedimenta, G);

    if (e.modo == 1) {
        beta = e.beta;
        if (!integrar_caida(W, beta, e.altura, G, H_PASO, 1, &r)) {
            fprintf(stderr, "No se alcanzo el suelo en %d pasos.\n", MAX_PASOS);
            return 1;
        }
        mostrar_salida(&e, W, beta, &r, 0);
    } else {
        if (!buscar_beta(W, e.altura, G, H_PASO, V_META, TOL_V, &beta, &r)) {
            fprintf(stderr, "No se encontro beta dentro de la tolerancia.\n");
            printf("Mejor aproximacion: beta=%.6f, v_suelo=%.6f m/s\n",
                   beta, r.v_suelo);
            return 1;
        }
        printf("\nVerificacion con beta=%.6f:\n", beta);
        if (!integrar_caida(W, beta, e.altura, G, H_PASO, 1, &r)) {
            fprintf(stderr, "No se alcanzo el suelo en la verificacion.\n");
            return 1;
        }
        mostrar_salida(&e, W, beta, &r, 1);
    }

    return 0;
}
