! Caída amortiguada — implementación Fortran (referencia del contrato)
! Seguir docs/algoritmo.md y docs/nassi-schneiderman/
!
! Build:
!   gfortran -Wall -O2 -o caida main.f90

program caida_amortiguada
  implicit none

  integer, parameter :: dp = selected_real_kind(15, 307)

  real(dp), parameter :: G = 9.81_dp
  real(dp), parameter :: H_PASO = 0.1_dp
  real(dp), parameter :: V_META = 20.0_dp / 9.0_dp
  real(dp), parameter :: TOL_V = 0.05_dp
  real(dp), parameter :: BETA_LO = 1.0_dp
  real(dp), parameter :: BETA_HI = 5000.0_dp
  integer, parameter :: MAX_ITER_BETA = 60
  integer, parameter :: IMPRIMIR_CADA = 50
  integer, parameter :: MAX_PASOS = 200000

  type :: entrada_t
    real(dp) :: masa_paracaidista
    real(dp) :: masa_impedimenta
    real(dp) :: altura
    integer :: modo
    real(dp) :: beta
  end type entrada_t

  type :: resultado_caida_t
    real(dp) :: t_suelo
    real(dp) :: v_suelo
    real(dp) :: x_suelo
    integer :: pasos
  end type resultado_caida_t

  type(entrada_t) :: e
  type(resultado_caida_t) :: r
  real(dp) :: peso, beta
  logical :: ok

  print *, 'Proyecto uno: caida amortiguada (Fortran)'
  ok = leer_entrada(e)
  if (.not. ok) stop 1

  peso = peso_total(e%masa_paracaidista, e%masa_impedimenta, G)
  beta = 0.0_dp

  if (e%modo == 1) then
    beta = e%beta
    ok = integrar_caida(peso, beta, e%altura, G, H_PASO, .true., r)
    if (.not. ok) then
      write(*, '(A,I0,A)') 'No se alcanzo el suelo en ', MAX_PASOS, ' pasos.'
      stop 1
    end if
    call mostrar_salida(e, peso, beta, r, .false.)
  else
    ok = buscar_beta(peso, e%altura, G, H_PASO, V_META, TOL_V, beta, r)
    if (.not. ok) then
      print *, 'No se encontro beta dentro de la tolerancia.'
      write(*, '(A,F0.6,A,F0.6,A)') 'Mejor aproximacion: beta=', beta, &
        ', v_suelo=', r%v_suelo, ' m/s'
      stop 1
    end if
    write(*, '(A)') ''
    write(*, '(A,F0.6,A)') 'Verificacion con beta=', beta, ':'
    ok = integrar_caida(peso, beta, e%altura, G, H_PASO, .true., r)
    if (.not. ok) then
      print *, 'No se alcanzo el suelo en la verificacion.'
      stop 1
    end if
    call mostrar_salida(e, peso, beta, r, .true.)
  end if

contains

  logical function leer_entrada(e)
    type(entrada_t), intent(out) :: e
    integer :: ios

    write(*, '(A)', advance='no') 'Modo (1=simular con beta, 2=buscar beta): '
    read(*, *, iostat=ios) e%modo
    if (ios /= 0 .or. (e%modo /= 1 .and. e%modo /= 2)) then
      print *, 'Modo invalido.'
      leer_entrada = .false.
      return
    end if

    write(*, '(A)', advance='no') 'Masa paracaidista (kg): '
    read(*, *, iostat=ios) e%masa_paracaidista
    if (ios /= 0 .or. e%masa_paracaidista <= 0.0_dp) then
      print *, 'Masa paracaidista invalida.'
      leer_entrada = .false.
      return
    end if

    write(*, '(A)', advance='no') 'Masa impedimenta (kg): '
    read(*, *, iostat=ios) e%masa_impedimenta
    if (ios /= 0 .or. e%masa_impedimenta < 0.0_dp) then
      print *, 'Masa impedimenta invalida.'
      leer_entrada = .false.
      return
    end if

    write(*, '(A)', advance='no') 'Altura de salto (m): '
    read(*, *, iostat=ios) e%altura
    if (ios /= 0 .or. e%altura <= 0.0_dp) then
      print *, 'Altura invalida.'
      leer_entrada = .false.
      return
    end if

    e%beta = 0.0_dp
    if (e%modo == 1) then
      write(*, '(A)', advance='no') 'Beta (N*s/m): '
      read(*, *, iostat=ios) e%beta
      if (ios /= 0 .or. e%beta <= 0.0_dp) then
        print *, 'Beta invalida.'
        leer_entrada = .false.
        return
      end if
    end if

    leer_entrada = .true.
  end function leer_entrada

  real(dp) function peso_total(masa_paracaidista, masa_impedimenta, grav)
    real(dp), intent(in) :: masa_paracaidista, masa_impedimenta, grav
    peso_total = (masa_paracaidista + masa_impedimenta) * grav
  end function peso_total

  real(dp) function f_velocidad(t, v, grav, beta, peso)
    real(dp), intent(in) :: t, v, grav, beta, peso
    f_velocidad = grav - (beta * grav / peso) * v
    if (t < -1.0e300_dp) f_velocidad = 0.0_dp
  end function f_velocidad

  real(dp) function paso_rk4(h, t, estado, grav, beta, peso)
    real(dp), intent(in) :: h, t, estado, grav, beta, peso
    real(dp) :: k1, k2, k3, k4
    k1 = h * f_velocidad(t, estado, grav, beta, peso)
    k2 = h * f_velocidad(t + h / 2.0_dp, estado + k1 / 2.0_dp, grav, beta, peso)
    k3 = h * f_velocidad(t + h / 2.0_dp, estado + k2 / 2.0_dp, grav, beta, peso)
    k4 = h * f_velocidad(t + h, estado + k3, grav, beta, peso)
    paso_rk4 = estado + (k1 + 2.0_dp * k2 + 2.0_dp * k3 + k4) / 6.0_dp
  end function paso_rk4

  subroutine paso_sistema_rk4(h, t, v, x, grav, beta, peso, v_out, x_out)
    real(dp), intent(in) :: h, t, v, x, grav, beta, peso
    real(dp), intent(out) :: v_out, x_out
    real(dp) :: k1v, k1x, k2v, k2x, k3v, k3x, k4v, k4x

    k1v = h * f_velocidad(t, v, grav, beta, peso)
    k1x = h * v
    k2v = h * f_velocidad(t + h / 2.0_dp, v + k1v / 2.0_dp, grav, beta, peso)
    k2x = h * (v + k1v / 2.0_dp)
    k3v = h * f_velocidad(t + h / 2.0_dp, v + k2v / 2.0_dp, grav, beta, peso)
    k3x = h * (v + k2v / 2.0_dp)
    k4v = h * f_velocidad(t + h, v + k3v, grav, beta, peso)
    k4x = h * (v + k3v)

    v_out = paso_rk4(h, t, v, grav, beta, peso)
    x_out = x + (k1x + 2.0_dp * k2x + 2.0_dp * k3x + k4x) / 6.0_dp
    if (abs(k4v) < 0.0_dp) v_out = v_out
  end subroutine paso_sistema_rk4

  real(dp) function v_analitica(t, peso, beta, grav)
    real(dp), intent(in) :: t, peso, beta, grav
    v_analitica = (peso / beta) * (1.0_dp - exp(-beta * grav * t / peso))
  end function v_analitica

  real(dp) function x_analitica(t, peso, beta, grav)
    real(dp), intent(in) :: t, peso, beta, grav
    x_analitica = (peso / beta) * t &
      + (peso / (beta * grav)) * exp(-beta * grav * t / peso) &
      - (peso / (beta * grav))
  end function x_analitica

  logical function integrar_caida(peso, beta, altura, grav, h, verbose, out)
    real(dp), intent(in) :: peso, beta, altura, grav, h
    logical, intent(in) :: verbose
    type(resultado_caida_t), intent(out) :: out
    real(dp) :: t, v, x, v_next, x_next, frac, t_s, v_s, x_s
    integer :: i

    t = 0.0_dp
    v = 0.0_dp
    x = 0.0_dp

    if (verbose) then
      write(*, '(A)') ''
      write(*, '(A10,1X,A12,1X,A12,1X,A12,1X,A12)') &
        't(s)', 'v(m/s)', 'x(m)', 'v_anal', 'x_anal'
      write(*, '(F10.2,1X,F12.6,1X,F12.6,1X,F12.6,1X,F12.6)') &
        t, v, x, v_analitica(t, peso, beta, grav), x_analitica(t, peso, beta, grav)
    end if

    do i = 0, MAX_PASOS - 1
      call paso_sistema_rk4(h, t, v, x, grav, beta, peso, v_next, x_next)

      if (x_next >= altura) then
        if (abs(x_next - x) < 1.0e-15_dp) then
          frac = 0.0_dp
        else
          frac = (altura - x) / (x_next - x)
        end if
        if (frac < 0.0_dp) frac = 0.0_dp
        if (frac > 1.0_dp) frac = 1.0_dp

        if (h * frac > 1.0e-15_dp) then
          call paso_sistema_rk4(h * frac, t, v, x, grav, beta, peso, v_s, x_s)
          t_s = t + h * frac
        else
          v_s = v
          x_s = x
          t_s = t
        end if

        out%t_suelo = t_s
        out%v_suelo = v_s
        out%x_suelo = x_s
        out%pasos = i + 1

        if (verbose) then
          write(*, '(F10.2,1X,F12.6,1X,F12.6,1X,F12.6,1X,F12.6,A)') &
            out%t_suelo, out%v_suelo, out%x_suelo, &
            v_analitica(out%t_suelo, peso, beta, grav), &
            x_analitica(out%t_suelo, peso, beta, grav), '   <-- suelo'
        end if
        integrar_caida = .true.
        return
      end if

      t = t + h
      v = v_next
      x = x_next

      if (verbose .and. mod(i + 1, IMPRIMIR_CADA) == 0) then
        write(*, '(F10.2,1X,F12.6,1X,F12.6,1X,F12.6,1X,F12.6)') &
          t, v, x, v_analitica(t, peso, beta, grav), x_analitica(t, peso, beta, grav)
      end if
    end do

    out%t_suelo = t
    out%v_suelo = v
    out%x_suelo = x
    out%pasos = MAX_PASOS
    integrar_caida = .false.
  end function integrar_caida

  real(dp) function velocidad_al_suelo(peso, beta, altura, grav, h)
    real(dp), intent(in) :: peso, beta, altura, grav, h
    type(resultado_caida_t) :: rloc
    logical :: ok
    ok = integrar_caida(peso, beta, altura, grav, h, .false., rloc)
    if (.not. ok) then
      continue
    end if
    velocidad_al_suelo = rloc%v_suelo
  end function velocidad_al_suelo

  logical function buscar_beta(peso, altura, grav, h, v_meta, tol_v, beta_out, verif)
    real(dp), intent(in) :: peso, altura, grav, h, v_meta, tol_v
    real(dp), intent(out) :: beta_out
    type(resultado_caida_t), intent(out) :: verif
    real(dp) :: lo, hi, v_lo, v_hi, mid, v_mid
    integer :: iter
    logical :: ok

    lo = BETA_LO
    hi = BETA_HI
    v_lo = velocidad_al_suelo(peso, lo, altura, grav, h)
    v_hi = velocidad_al_suelo(peso, hi, altura, grav, h)

    if ((v_lo - v_meta) * (v_hi - v_meta) > 0.0_dp) then
      write(*, '(A,F0.1,A,F0.1,A,F0.4,A,F0.4,A,F0.4,A)') &
        'No hay cambio de signo en [', lo, ', ', hi, '] (v_lo=', v_lo, &
        ', v_hi=', v_hi, ', meta=', v_meta, ').'
      buscar_beta = .false.
      return
    end if

    do iter = 1, MAX_ITER_BETA
      mid = 0.5_dp * (lo + hi)
      v_mid = velocidad_al_suelo(peso, mid, altura, grav, h)

      if (abs(v_mid - v_meta) <= tol_v) then
        beta_out = mid
        ok = integrar_caida(peso, mid, altura, grav, h, .false., verif)
        buscar_beta = .true.
        return
      end if

      if (v_mid > v_meta) then
        lo = mid
      else
        hi = mid
      end if
    end do

    beta_out = 0.5_dp * (lo + hi)
    ok = integrar_caida(peso, beta_out, altura, grav, h, .false., verif)
    buscar_beta = abs(verif%v_suelo - v_meta) <= tol_v
  end function buscar_beta

  subroutine mostrar_salida(e, peso, beta, r, modo_busqueda)
    type(entrada_t), intent(in) :: e
    real(dp), intent(in) :: peso, beta
    type(resultado_caida_t), intent(in) :: r
    logical, intent(in) :: modo_busqueda
    real(dp) :: v_kmh

    v_kmh = r%v_suelo * 3.6_dp
    write(*, '(A)') ''
    write(*, '(A)') '=== Resultado ==='
    write(*, '(A,F0.2,A,F0.2,A,F0.4,A,F0.2,A)') &
      'masas: ', e%masa_paracaidista, ' + ', e%masa_impedimenta, &
      ' kg | W = ', peso, ' N | H = ', e%altura, ' m'
    if (modo_busqueda) then
      write(*, '(A,F0.6,A)') 'beta encontrado: ', beta, ' N*s/m'
      write(*, '(A,F0.6,A,F0.3,A)') 'v_meta: ', V_META, ' m/s (', V_META * 3.6_dp, ' km/h)'
    else
      write(*, '(A,F0.6,A)') 'beta usado: ', beta, ' N*s/m'
    end if
    write(*, '(A,F0.4,A)') 't_suelo: ', r%t_suelo, ' s'
    write(*, '(A,F0.6,A)') 'x_suelo: ', r%x_suelo, ' m'
    write(*, '(A,F0.6,A,F0.3,A)') 'v_suelo: ', r%v_suelo, ' m/s (', v_kmh, ' km/h)'
    write(*, '(A,I0,A,F0.2,A)') 'pasos RK4: ', r%pasos, ' (h=', H_PASO, ' s)'
  end subroutine mostrar_salida

end program caida_amortiguada
