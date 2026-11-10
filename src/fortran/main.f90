! Caida amortiguada de un paracaidista - implementacion en Fortran 2008
! IC4700 Lenguajes de Programacion - Proyecto programado 1
!
! Resuelve  (W/g) dv/dt = W - beta*v,  v(0) = 0,  junto con dx/dt = v,
! mediante Runge-Kutta de 4.o orden, hasta que el paracaidista llega al
! suelo (x >= altura). En modo 2 busca por biseccion el valor de beta que
! produce una velocidad de aterrizaje de ~8 km/h.
!
! Diseno: docs/algoritmo.md y docs/nassi-schneiderman/ (un diagrama por
! subprograma; los nombres y parametros coinciden con los diagramas).
! Programacion estructurada: cada subprograma tiene una sola entrada y una
! sola salida (sin return/exit/cycle); comunicacion solo por argumentos.
! Los subprogramas estan en un MODULE (y no en CONTAINS del programa) para
! que no puedan ver las variables del programa principal (sin acoplamiento
! por asociacion con el anfitrion).
!
! Compilar:  gfortran -std=f2008 -Wall -O2 -o caida main.f90

module caida_mod
  use, intrinsic :: iso_fortran_env, only: error_unit
  implicit none
  private
  public :: dp, G, H_PASO, V_META, TOL_V, MAX_PASOS
  public :: entrada_t, resultado_caida_t
  public :: leer_entrada, peso_total, buscar_beta, integrar_caida
  public :: mostrar_tabla, mostrar_salida

  integer, parameter :: dp = selected_real_kind(15, 307)

  ! ---- Constantes congeladas (docs/algoritmo.md) ----
  real(dp), parameter :: G = 9.81_dp               ! gravedad [m/s^2]
  real(dp), parameter :: H_PASO = 0.1_dp           ! paso RK4 [s]
  real(dp), parameter :: V_META = 20.0_dp / 9.0_dp ! 8 km/h en m/s
  real(dp), parameter :: TOL_V = 0.05_dp           ! tolerancia de v_suelo [m/s]
  real(dp), parameter :: BETA_LO = 1.0_dp          ! extremo inferior de la biseccion
  real(dp), parameter :: Z_ESTABLE = 2.0_dp        ! beta_hi = Z_ESTABLE*W/(g*h)
  integer, parameter :: MAX_ITER_BETA = 60         ! iteraciones maximas de biseccion
  integer, parameter :: IMPRIMIR_CADA = 50         ! una fila de tabla cada 50 pasos
  integer, parameter :: MAX_PASOS = 200000         ! pasos maximos por simulacion
  integer, parameter :: MAX_FILAS = MAX_PASOS / IMPRIMIR_CADA + 2

  ! ---- Registros ----
  type :: entrada_t
    integer :: modo                   ! 1 = beta dado, 2 = buscar beta
    real(dp) :: masa_paracaidista     ! [kg]
    real(dp) :: masa_impedimenta      ! [kg]
    real(dp) :: altura                ! [m]
    real(dp) :: beta                  ! [N*s/m] (solo modo 1)
  end type entrada_t

  type :: fila_t
    real(dp) :: t, v, x               ! [s], [m/s], [m]
  end type fila_t

  type :: resultado_caida_t
    logical :: aterrizo               ! verdadero si se alcanzo x >= altura
    real(dp) :: t_suelo               ! instante de aterrizaje [s]
    real(dp) :: v_suelo               ! velocidad de aterrizaje [m/s]
    real(dp) :: x_suelo               ! distancia recorrida al aterrizar [m]
    integer :: pasos                  ! pasos RK4 realizados
    integer :: n_filas                ! filas usadas en la tabla
    type(fila_t) :: filas(MAX_FILAS)  ! tabla (t, v, x)
  end type resultado_caida_t

contains

  ! leer_entrada
  ! Funcionalidad: pedir y validar modo, masa del paracaidista, masa de la
  !   impedimenta, altura y (solo en modo 1) beta. Una lectura no numerica
  !   se considera un valor invalido.
  ! Entradas: datos del teclado.
  ! Salidas: e (registro entrada_t); ok = .true. si todos los datos son validos.
  subroutine leer_entrada(e, ok)
    type(entrada_t), intent(out) :: e
    logical, intent(out) :: ok
    character(len=32) :: campo
    integer :: ios

    campo = 'modo'
    write(*, '(A)', advance='no') 'Modo (1=simular con beta, 2=buscar beta): '
    read(*, *, iostat=ios) e%modo
    ok = (ios == 0)
    if (ok) ok = (e%modo == 1 .or. e%modo == 2)
    e%beta = 0.0_dp

    if (ok) then
      campo = 'masa del paracaidista'
      write(*, '(A)', advance='no') 'Masa paracaidista (kg): '
      read(*, *, iostat=ios) e%masa_paracaidista
      ok = (ios == 0)
      if (ok) ok = (e%masa_paracaidista > 0.0_dp)
    end if
    if (ok) then
      campo = 'masa de la impedimenta'
      write(*, '(A)', advance='no') 'Masa impedimenta (kg): '
      read(*, *, iostat=ios) e%masa_impedimenta
      ok = (ios == 0)
      if (ok) ok = (e%masa_impedimenta >= 0.0_dp)
    end if
    if (ok) then
      campo = 'altura'
      write(*, '(A)', advance='no') 'Altura de salto (m): '
      read(*, *, iostat=ios) e%altura
      ok = (ios == 0)
      if (ok) ok = (e%altura > 0.0_dp)
    end if
    if (ok .and. e%modo == 1) then
      campo = 'beta'
      write(*, '(A)', advance='no') 'Beta (N*s/m): '
      read(*, *, iostat=ios) e%beta
      ok = (ios == 0)
      if (ok) ok = (e%beta > 0.0_dp)
    end if
    if (.not. ok) then
      write(error_unit, '(2A)') 'Valor invalido: ', trim(campo)
    end if
  end subroutine leer_entrada

  ! peso_total
  ! Funcionalidad: peso combinado W = (masa_paracaidista + masa_impedimenta) * g.
  ! Entradas: masa_paracaidista [kg], masa_impedimenta [kg], g [m/s^2].
  ! Salida: W [N].
  real(dp) function peso_total(masa_paracaidista, masa_impedimenta, g)
    real(dp), intent(in) :: masa_paracaidista, masa_impedimenta, g
    peso_total = (masa_paracaidista + masa_impedimenta) * g
  end function peso_total

  ! f_velocidad
  ! Funcionalidad: lado derecho de la EDO, dv/dt = g - (beta*g/W)*v.
  !   La EDO es autonoma (no depende de t).
  ! Entradas: v [m/s], g [m/s^2], beta [N*s/m], W [N].
  ! Salida: dv/dt [m/s^2].
  real(dp) function f_velocidad(v, g, beta, W)
    real(dp), intent(in) :: v, g, beta, W
    f_velocidad = g - (beta * g / W) * v
  end function f_velocidad

  ! paso_rk4
  ! Funcionalidad: un paso de Runge-Kutta 4 del sistema acoplado
  !   v' = f_velocidad(v), x' = v.
  ! Entradas: h [s], v [m/s], x [m], g, beta, W (parametros de f_velocidad).
  ! Salidas: v_sig, x_sig (estado despues del paso h).
  subroutine paso_rk4(h, v, x, g, beta, W, v_sig, x_sig)
    real(dp), intent(in) :: h, v, x, g, beta, W
    real(dp), intent(out) :: v_sig, x_sig
    real(dp) :: k1v, k1x, k2v, k2x, k3v, k3x, k4v, k4x

    k1v = h * f_velocidad(v, g, beta, W)
    k1x = h * v
    k2v = h * f_velocidad(v + k1v / 2.0_dp, g, beta, W)
    k2x = h * (v + k1v / 2.0_dp)
    k3v = h * f_velocidad(v + k2v / 2.0_dp, g, beta, W)
    k3x = h * (v + k2v / 2.0_dp)
    k4v = h * f_velocidad(v + k3v, g, beta, W)
    k4x = h * (v + k3v)

    v_sig = v + (k1v + 2.0_dp * k2v + 2.0_dp * k3v + k4v) / 6.0_dp
    x_sig = x + (k1x + 2.0_dp * k2x + 2.0_dp * k3x + k4x) / 6.0_dp
  end subroutine paso_rk4

  ! registrar_fila
  ! Funcionalidad: agregar la fila (t, v, x) a la tabla de r, si hay capacidad.
  ! Entradas: r, t [s], v [m/s], x [m].
  ! Salidas: r%filas y r%n_filas actualizados.
  subroutine registrar_fila(r, t, v, x)
    type(resultado_caida_t), intent(inout) :: r
    real(dp), intent(in) :: t, v, x

    if (r%n_filas < MAX_FILAS) then
      r%n_filas = r%n_filas + 1
      r%filas(r%n_filas)%t = t
      r%filas(r%n_filas)%v = v
      r%filas(r%n_filas)%x = x
    end if
  end subroutine registrar_fila

  ! integrar_caida
  ! Funcionalidad: integrar la caida con paso_rk4 desde el reposo hasta que
  !   x >= altura; el ultimo paso se recorta a h*frac para estimar el instante
  !   y la velocidad de aterrizaje. Guarda la tabla (fila inicial, cada
  !   IMPRIMIR_CADA pasos y la de aterrizaje).
  !   Invariante del ciclo: x < altura, por lo que x_sig - x > 0 y frac en (0, 1].
  ! Entradas: W [N], beta [N*s/m], altura [m], g [m/s^2], h [s].
  ! Salidas: r (aterrizo, t_suelo, v_suelo, x_suelo, pasos, tabla).
  subroutine integrar_caida(W, beta, altura, g, h, r)
    real(dp), intent(in) :: W, beta, altura, g, h
    type(resultado_caida_t), intent(out) :: r
    real(dp) :: t, v, x, v_sig, x_sig, frac
    integer :: i
    logical :: aterrizo

    t = 0.0_dp
    v = 0.0_dp
    x = 0.0_dp
    i = 0
    aterrizo = .false.
    r%n_filas = 0
    call registrar_fila(r, t, v, x)

    do while (.not. aterrizo .and. i < MAX_PASOS)
      call paso_rk4(h, v, x, g, beta, W, v_sig, x_sig)
      if (x_sig >= altura) then
        frac = (altura - x) / (x_sig - x)
        call paso_rk4(h * frac, v, x, g, beta, W, v_sig, x_sig)
        t = t + h * frac
        aterrizo = .true.
      else
        t = t + h
      end if
      v = v_sig
      x = x_sig
      i = i + 1
      if (aterrizo .or. mod(i, IMPRIMIR_CADA) == 0) then
        call registrar_fila(r, t, v, x)
      end if
    end do

    r%aterrizo = aterrizo
    r%t_suelo = t
    r%v_suelo = v
    r%x_suelo = x
    r%pasos = i
  end subroutine integrar_caida

  ! buscar_beta
  ! Funcionalidad: hallar beta por biseccion tal que
  !   |v_suelo(beta) - v_meta| <= tol_v. Mas beta => menor v_suelo.
  !   hi = Z_ESTABLE*W/(g*h) mantiene |h*lambda| = 2 < 2.785 (RK4 estable).
  ! Entradas: W [N], altura [m], g [m/s^2], h [s], v_meta [m/s], tol_v [m/s].
  ! Salidas: beta (encontrado o mejor aproximacion) [N*s/m];
  !          encontrado = .true. si se cumplio la tolerancia.
  subroutine buscar_beta(W, altura, g, h, v_meta, tol_v, beta, encontrado)
    real(dp), intent(in) :: W, altura, g, h, v_meta, tol_v
    real(dp), intent(out) :: beta
    logical, intent(out) :: encontrado
    type(resultado_caida_t) :: r
    real(dp) :: lo, hi, v_lo, v_hi
    integer :: iter

    lo = BETA_LO
    hi = Z_ESTABLE * W / (g * h)
    call integrar_caida(W, lo, altura, g, h, r)
    v_lo = r%v_suelo
    call integrar_caida(W, hi, altura, g, h, r)
    v_hi = r%v_suelo
    encontrado = .false.
    iter = 0
    beta = (lo + hi) / 2.0_dp

    if ((v_lo - v_meta) * (v_hi - v_meta) <= 0.0_dp) then
      do while (.not. encontrado .and. iter < MAX_ITER_BETA)
        beta = (lo + hi) / 2.0_dp
        call integrar_caida(W, beta, altura, g, h, r)
        if (abs(r%v_suelo - v_meta) <= tol_v) then
          encontrado = .true.
        else if (r%v_suelo > v_meta) then
          lo = beta
        else
          hi = beta
        end if
        iter = iter + 1
      end do
    end if
  end subroutine buscar_beta

  ! v_analitica
  ! Funcionalidad: velocidad analitica v(t) = (W/beta)*(1 - exp(-beta*g*t/W)).
  ! Entradas: t [s], W [N], beta [N*s/m], g [m/s^2].
  ! Salida: v(t) [m/s].
  real(dp) function v_analitica(t, W, beta, g)
    real(dp), intent(in) :: t, W, beta, g
    v_analitica = (W / beta) * (1.0_dp - exp(-beta * g * t / W))
  end function v_analitica

  ! x_analitica
  ! Funcionalidad: distancia analitica
  !   x(t) = (W/beta)*t + (W/(beta*g))*exp(-beta*g*t/W) - W/(beta*g).
  ! Entradas: t [s], W [N], beta [N*s/m], g [m/s^2].
  ! Salida: x(t) [m].
  real(dp) function x_analitica(t, W, beta, g)
    real(dp), intent(in) :: t, W, beta, g
    x_analitica = (W / beta) * t + (W / (beta * g)) * exp(-beta * g * t / W) &
                  - W / (beta * g)
  end function x_analitica

  ! mostrar_tabla
  ! Funcionalidad: imprimir la tabla numerica (t, v, x) junto a la solucion
  !   analitica, marcando la fila de aterrizaje.
  ! Entradas: r (tabla), W [N], beta [N*s/m], g [m/s^2].
  ! Salidas: ninguna (pantalla).
  subroutine mostrar_tabla(r, W, beta, g)
    type(resultado_caida_t), intent(in) :: r
    real(dp), intent(in) :: W, beta, g
    integer :: k

    write(*, '(A)') ''
    write(*, '(A10,1X,A12,1X,A12,1X,A12,1X,A12)') 't(s)', 'v(m/s)', 'x(m)', 'v_anal', 'x_anal'
    do k = 1, r%n_filas
      write(*, '(F10.2,1X,F12.6,1X,F12.6,1X,F12.6,1X,F12.6)', advance='no') &
        r%filas(k)%t, r%filas(k)%v, r%filas(k)%x, &
        v_analitica(r%filas(k)%t, W, beta, g), &
        x_analitica(r%filas(k)%t, W, beta, g)
      if (r%aterrizo .and. k == r%n_filas) then
        write(*, '(A)', advance='no') '   [suelo]'
      end if
      write(*, '(A)') ''
    end do
  end subroutine mostrar_tabla

  ! mostrar_salida
  ! Funcionalidad: imprimir el resumen de resultados; el texto de beta
  !   depende de e%modo.
  ! Entradas: e, W [N], beta [N*s/m], r, h [s], v_meta [m/s].
  ! Salidas: ninguna (pantalla).
  subroutine mostrar_salida(e, W, beta, r, h, v_meta)
    type(entrada_t), intent(in) :: e
    real(dp), intent(in) :: W, beta, h, v_meta
    type(resultado_caida_t), intent(in) :: r

    write(*, '(A)') ''
    write(*, '(A)') '=== Resultado ==='
    write(*, '(A,F0.2,A,F0.2,A,F0.4,A,F0.2,A)') 'masas: ', e%masa_paracaidista, ' + ', &
      e%masa_impedimenta, ' kg | W = ', W, ' N | H = ', e%altura, ' m'
    if (e%modo == 2) then
      write(*, '(A,F0.6,A)') 'beta encontrado: ', beta, ' N*s/m'
      write(*, '(A,F0.6,A,F0.3,A)') 'v_meta: ', v_meta, ' m/s (', v_meta * 3.6_dp, ' km/h)'
    else
      write(*, '(A,F0.6,A)') 'beta usado: ', beta, ' N*s/m'
    end if
    write(*, '(A,F0.4,A)') 't_suelo: ', r%t_suelo, ' s'
    write(*, '(A,F0.6,A)') 'x_suelo: ', r%x_suelo, ' m'
    write(*, '(A,F0.6,A,F0.3,A)') 'v_suelo: ', r%v_suelo, ' m/s (', r%v_suelo * 3.6_dp, ' km/h)'
    write(*, '(A,I0,A,F4.2,A)') 'pasos RK4: ', r%pasos, ' (h = ', h, ' s)'
  end subroutine mostrar_salida

end module caida_mod


! Programa principal
! Funcionalidad: dirigir el flujo del programa segun el modo elegido.
! Entradas: ninguna (los datos los lee leer_entrada).
! Salida: codigo de salida (0 exito, 1 error).
program caida_amortiguada
  use, intrinsic :: iso_fortran_env, only: error_unit
  use caida_mod
  implicit none

  type(entrada_t) :: e
  type(resultado_caida_t) :: r
  real(dp) :: W, beta
  logical :: ok, encontrado
  integer :: codigo

  write(*, '(A)') 'Proyecto uno: caida amortiguada (Fortran)'
  call leer_entrada(e, ok)
  if (ok) then
    W = peso_total(e%masa_paracaidista, e%masa_impedimenta, G)
    if (e%modo == 1) then
      beta = e%beta
      encontrado = .true.
    else
      call buscar_beta(W, e%altura, G, H_PASO, V_META, TOL_V, beta, encontrado)
      if (.not. encontrado) then
        write(*, '(A)') 'Aviso: no se alcanzo TOL_V; se usa la mejor aproximacion'
      end if
    end if
    call integrar_caida(W, beta, e%altura, G, H_PASO, r)
    if (r%aterrizo) then
      call mostrar_tabla(r, W, beta, G)
      call mostrar_salida(e, W, beta, r, H_PASO, V_META)
      codigo = 0
    else
      write(error_unit, '(A,I0,A)') 'Sin aterrizaje: no se alcanzo el suelo en ', MAX_PASOS, ' pasos'
      codigo = 1
    end if
  else
    codigo = 1
  end if
  if (codigo /= 0) stop 1
end program caida_amortiguada
