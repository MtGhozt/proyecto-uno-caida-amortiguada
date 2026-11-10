/*
 * Caida amortiguada de un paracaidista - implementacion en C
 * IC4700 Lenguajes de Programacion - Proyecto programado 1
 *
 * Resuelve  (W/g) dv/dt = W - beta*v,  v(0) = 0,  junto con dx/dt = v,
 * mediante Runge-Kutta de 4.o orden, hasta que el paracaidista llega al
 * suelo (x >= altura). En modo 2 busca por biseccion el valor de beta que
 * produce una velocidad de aterrizaje de ~8 km/h.
 *
 * Diseno: docs/algoritmo.md y docs/nassi-schneiderman/ (un diagrama por
 * funcion; los nombres y parametros coinciden con los diagramas).
 * Programacion estructurada: cada funcion tiene una sola entrada y una sola
 * salida; los modulos se comunican solo por parametros (sin globales
 * modificables).
 *
 * Compilar:  gcc -std=c11 -Wall -Wextra -O2 -o caida main.c -lm
 */

#include <math.h>
#include <stdbool.h>
#include <stdio.h>

/* ---- Constantes congeladas (docs/algoritmo.md) ---- */
#define G             9.81          /* gravedad [m/s^2] */
#define H_PASO        0.1           /* paso RK4 [s] */
#define V_META        (20.0 / 9.0)  /* 8 km/h en m/s */
#define TOL_V         0.05          /* tolerancia de v_suelo [m/s] */
#define BETA_LO       1.0           /* extremo inferior de la biseccion [N*s/m] */
#define Z_ESTABLE     2.0           /* beta_hi = Z_ESTABLE*W/(g*h): RK4 estable */
#define MAX_ITER_BETA 60            /* iteraciones maximas de biseccion */
#define IMPRIMIR_CADA 50            /* una fila de tabla cada 50 pasos */
#define MAX_PASOS     200000        /* pasos maximos por simulacion */
#define MAX_FILAS     (MAX_PASOS / IMPRIMIR_CADA + 2)

/* ---- Registros ---- */
typedef struct {
    int    modo;               /* 1 = beta dado, 2 = buscar beta */
    double masa_paracaidista;  /* [kg] */
    double masa_impedimenta;   /* [kg] */
    double altura;             /* [m] */
    double beta;               /* [N*s/m] (solo modo 1) */
} Entrada;

typedef struct {
    double t, v, x;            /* [s], [m/s], [m] */
} Fila;

typedef struct {
    bool   aterrizo;           /* verdadero si se alcanzo x >= altura */
    double t_suelo;            /* instante de aterrizaje [s] */
    double v_suelo;            /* velocidad de aterrizaje [m/s] */
    double x_suelo;            /* distancia recorrida al aterrizar [m] */
    int    pasos;              /* pasos RK4 realizados */
    int    n_filas;            /* filas usadas en la tabla */
    Fila   filas[MAX_FILAS];   /* tabla (t, v, x) */
} ResultadoCaida;

/*
 * leer_entrada
 * Funcionalidad: pedir y validar modo, masa del paracaidista, masa de la
 *   impedimenta, altura y (solo en modo 1) beta. Una lectura no numerica
 *   se considera un valor invalido.
 * Entradas: datos del teclado.
 * Salidas: *e (registro Entrada); *ok = verdadero si todos los datos son validos.
 */
static void leer_entrada(Entrada *e, bool *ok)
{
    const char *campo = "modo";

    printf("Modo (1=simular con beta, 2=buscar beta): ");
    *ok = (scanf("%d", &e->modo) == 1) && (e->modo == 1 || e->modo == 2);
    e->beta = 0.0;

    if (*ok) {
        campo = "masa del paracaidista";
        printf("Masa paracaidista (kg): ");
        *ok = (scanf("%lf", &e->masa_paracaidista) == 1) && (e->masa_paracaidista > 0.0);
    }
    if (*ok) {
        campo = "masa de la impedimenta";
        printf("Masa impedimenta (kg): ");
        *ok = (scanf("%lf", &e->masa_impedimenta) == 1) && (e->masa_impedimenta >= 0.0);
    }
    if (*ok) {
        campo = "altura";
        printf("Altura de salto (m): ");
        *ok = (scanf("%lf", &e->altura) == 1) && (e->altura > 0.0);
    }
    if (*ok && e->modo == 1) {
        campo = "beta";
        printf("Beta (N*s/m): ");
        *ok = (scanf("%lf", &e->beta) == 1) && (e->beta > 0.0);
    }
    if (!*ok) {
        fprintf(stderr, "Valor invalido: %s\n", campo);
    }
}

/*
 * peso_total
 * Funcionalidad: peso combinado W = (masa_paracaidista + masa_impedimenta) * g.
 * Entradas: masa_paracaidista [kg], masa_impedimenta [kg], g [m/s^2].
 * Salida: W [N].
 */
static double peso_total(double masa_paracaidista, double masa_impedimenta, double g)
{
    return (masa_paracaidista + masa_impedimenta) * g;
}

/*
 * f_velocidad
 * Funcionalidad: lado derecho de la EDO, dv/dt = g - (beta*g/W)*v.
 *   La EDO es autonoma (no depende de t).
 * Entradas: v [m/s], g [m/s^2], beta [N*s/m], W [N].
 * Salida: dv/dt [m/s^2].
 */
static double f_velocidad(double v, double g, double beta, double W)
{
    return g - (beta * g / W) * v;
}

/*
 * paso_rk4
 * Funcionalidad: un paso de Runge-Kutta 4 del sistema acoplado
 *   v' = f_velocidad(v), x' = v.
 * Entradas: h [s], v [m/s], x [m], g, beta, W (parametros de f_velocidad).
 * Salidas: *v_sig, *x_sig (estado despues del paso h).
 */
static void paso_rk4(double h, double v, double x, double g, double beta, double W,
                     double *v_sig, double *x_sig)
{
    double k1v = h * f_velocidad(v, g, beta, W);
    double k1x = h * v;
    double k2v = h * f_velocidad(v + k1v / 2.0, g, beta, W);
    double k2x = h * (v + k1v / 2.0);
    double k3v = h * f_velocidad(v + k2v / 2.0, g, beta, W);
    double k3x = h * (v + k2v / 2.0);
    double k4v = h * f_velocidad(v + k3v, g, beta, W);
    double k4x = h * (v + k3v);

    *v_sig = v + (k1v + 2.0 * k2v + 2.0 * k3v + k4v) / 6.0;
    *x_sig = x + (k1x + 2.0 * k2x + 2.0 * k3x + k4x) / 6.0;
}

/*
 * registrar_fila
 * Funcionalidad: agregar la fila (t, v, x) a la tabla de r, si hay capacidad.
 * Entradas: *r, t [s], v [m/s], x [m].
 * Salidas: r->filas y r->n_filas actualizados.
 */
static void registrar_fila(ResultadoCaida *r, double t, double v, double x)
{
    if (r->n_filas < MAX_FILAS) {
        r->filas[r->n_filas].t = t;   /* C usa indices base 0 */
        r->filas[r->n_filas].v = v;
        r->filas[r->n_filas].x = x;
        r->n_filas = r->n_filas + 1;
    }
}

/*
 * integrar_caida
 * Funcionalidad: integrar la caida con paso_rk4 desde el reposo hasta que
 *   x >= altura; el ultimo paso se recorta a h*frac para estimar el instante
 *   y la velocidad de aterrizaje. Guarda la tabla (fila inicial, cada
 *   IMPRIMIR_CADA pasos y la de aterrizaje).
 *   Invariante del ciclo: x < altura, por lo que x_sig - x > 0 y frac en (0, 1].
 * Entradas: W [N], beta [N*s/m], altura [m], g [m/s^2], h [s].
 * Salidas: *r (aterrizo, t_suelo, v_suelo, x_suelo, pasos, tabla).
 */
static void integrar_caida(double W, double beta, double altura, double g, double h,
                           ResultadoCaida *r)
{
    double t = 0.0, v = 0.0, x = 0.0;
    double v_sig, x_sig, frac;
    int i = 0;
    bool aterrizo = false;

    r->n_filas = 0;
    registrar_fila(r, t, v, x);

    while (!aterrizo && i < MAX_PASOS) {
        paso_rk4(h, v, x, g, beta, W, &v_sig, &x_sig);
        if (x_sig >= altura) {
            frac = (altura - x) / (x_sig - x);
            paso_rk4(h * frac, v, x, g, beta, W, &v_sig, &x_sig);
            t = t + h * frac;
            aterrizo = true;
        } else {
            t = t + h;
        }
        v = v_sig;
        x = x_sig;
        i = i + 1;
        if (aterrizo || i % IMPRIMIR_CADA == 0) {
            registrar_fila(r, t, v, x);
        }
    }

    r->aterrizo = aterrizo;
    r->t_suelo = t;
    r->v_suelo = v;
    r->x_suelo = x;
    r->pasos = i;
}

/*
 * buscar_beta
 * Funcionalidad: hallar beta por biseccion tal que
 *   |v_suelo(beta) - v_meta| <= tol_v. Mas beta => menor v_suelo.
 *   hi = Z_ESTABLE*W/(g*h) mantiene |h*lambda| = 2 < 2.785 (RK4 estable).
 * Entradas: W [N], altura [m], g [m/s^2], h [s], v_meta [m/s], tol_v [m/s].
 * Salidas: *beta (encontrado o mejor aproximacion) [N*s/m];
 *          *encontrado = verdadero si se cumplio la tolerancia.
 */
static void buscar_beta(double W, double altura, double g, double h,
                        double v_meta, double tol_v,
                        double *beta, bool *encontrado)
{
    ResultadoCaida r;
    double lo = BETA_LO;
    double hi = Z_ESTABLE * W / (g * h);
    double v_lo, v_hi;
    int iter;

    integrar_caida(W, lo, altura, g, h, &r);
    v_lo = r.v_suelo;
    integrar_caida(W, hi, altura, g, h, &r);
    v_hi = r.v_suelo;
    *encontrado = false;
    iter = 0;
    *beta = (lo + hi) / 2.0;

    if ((v_lo - v_meta) * (v_hi - v_meta) <= 0.0) {
        while (!*encontrado && iter < MAX_ITER_BETA) {
            *beta = (lo + hi) / 2.0;
            integrar_caida(W, *beta, altura, g, h, &r);
            if (fabs(r.v_suelo - v_meta) <= tol_v) {
                *encontrado = true;
            } else if (r.v_suelo > v_meta) {
                lo = *beta;
            } else {
                hi = *beta;
            }
            iter = iter + 1;
        }
    }
}

/*
 * v_analitica
 * Funcionalidad: velocidad analitica v(t) = (W/beta)*(1 - exp(-beta*g*t/W)).
 * Entradas: t [s], W [N], beta [N*s/m], g [m/s^2].
 * Salida: v(t) [m/s].
 */
static double v_analitica(double t, double W, double beta, double g)
{
    return (W / beta) * (1.0 - exp(-beta * g * t / W));
}

/*
 * x_analitica
 * Funcionalidad: distancia analitica
 *   x(t) = (W/beta)*t + (W/(beta*g))*exp(-beta*g*t/W) - W/(beta*g).
 * Entradas: t [s], W [N], beta [N*s/m], g [m/s^2].
 * Salida: x(t) [m].
 */
static double x_analitica(double t, double W, double beta, double g)
{
    return (W / beta) * t + (W / (beta * g)) * exp(-beta * g * t / W) - W / (beta * g);
}

/*
 * mostrar_tabla
 * Funcionalidad: imprimir la tabla numerica (t, v, x) junto a la solucion
 *   analitica, marcando la fila de aterrizaje.
 * Entradas: *r (tabla), W [N], beta [N*s/m], g [m/s^2].
 * Salidas: ninguna (pantalla).
 */
static void mostrar_tabla(const ResultadoCaida *r, double W, double beta, double g)
{
    int k;

    printf("\n%10s %12s %12s %12s %12s\n", "t(s)", "v(m/s)", "x(m)", "v_anal", "x_anal");
    for (k = 0; k < r->n_filas; k++) {
        printf("%10.2f %12.6f %12.6f %12.6f %12.6f",
               r->filas[k].t, r->filas[k].v, r->filas[k].x,
               v_analitica(r->filas[k].t, W, beta, g),
               x_analitica(r->filas[k].t, W, beta, g));
        if (r->aterrizo && k == r->n_filas - 1) {
            printf("   [suelo]");
        }
        printf("\n");
    }
}

/*
 * mostrar_salida
 * Funcionalidad: imprimir el resumen de resultados; el texto de beta
 *   depende de e->modo.
 * Entradas: *e, W [N], beta [N*s/m], *r, h [s], v_meta [m/s].
 * Salidas: ninguna (pantalla).
 */
static void mostrar_salida(const Entrada *e, double W, double beta,
                           const ResultadoCaida *r, double h, double v_meta)
{
    printf("\n=== Resultado ===\n");
    printf("masas: %.2f + %.2f kg | W = %.4f N | H = %.2f m\n",
           e->masa_paracaidista, e->masa_impedimenta, W, e->altura);
    if (e->modo == 2) {
        printf("beta encontrado: %.6f N*s/m\n", beta);
        printf("v_meta: %.6f m/s (%.3f km/h)\n", v_meta, v_meta * 3.6);
    } else {
        printf("beta usado: %.6f N*s/m\n", beta);
    }
    printf("t_suelo: %.4f s\n", r->t_suelo);
    printf("x_suelo: %.6f m\n", r->x_suelo);
    printf("v_suelo: %.6f m/s (%.3f km/h)\n", r->v_suelo, r->v_suelo * 3.6);
    printf("pasos RK4: %d (h = %.2f s)\n", r->pasos, h);
}

/*
 * main
 * Funcionalidad: dirigir el flujo del programa segun el modo elegido.
 * Entradas: ninguna (los datos los lee leer_entrada).
 * Salida: codigo de salida (0 exito, 1 error).
 */
int main(void)
{
    Entrada e;
    ResultadoCaida r;
    double W, beta;
    bool ok, encontrado;
    int codigo;

    printf("Proyecto uno: caida amortiguada (C)\n");
    leer_entrada(&e, &ok);
    if (ok) {
        W = peso_total(e.masa_paracaidista, e.masa_impedimenta, G);
        if (e.modo == 1) {
            beta = e.beta;
            encontrado = true;
        } else {
            buscar_beta(W, e.altura, G, H_PASO, V_META, TOL_V, &beta, &encontrado);
            if (!encontrado) {
                printf("Aviso: no se alcanzo TOL_V; se usa la mejor aproximacion\n");
            }
        }
        integrar_caida(W, beta, e.altura, G, H_PASO, &r);
        if (r.aterrizo) {
            mostrar_tabla(&r, W, beta, G);
            mostrar_salida(&e, W, beta, &r, H_PASO, V_META);
            codigo = 0;
        } else {
            fprintf(stderr, "Sin aterrizaje: no se alcanzo el suelo en %d pasos\n", MAX_PASOS);
            codigo = 1;
        }
    } else {
        codigo = 1;
    }
    return codigo;
}
