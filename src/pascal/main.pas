{ Caída amortiguada — implementación Pascal (Free Pascal)
  Seguir docs/algoritmo.md y docs/nassi-schneiderman/

  Build:
    fpc -O2 main.pas
}

{$mode objfpc}
{$H+}

program CaidaAmortiguada;

uses
  SysUtils, Math;

const
  G = 9.81;
  H_PASO = 0.1;
  V_META = 20.0 / 9.0;
  TOL_V = 0.05;
  BETA_LO = 1.0;
  BETA_HI = 5000.0;
  MAX_ITER_BETA = 60;
  IMPRIMIR_CADA = 50;
  MAX_PASOS = 200000;

type
  TEntrada = record
    masa_paracaidista: Double;
    masa_impedimenta: Double;
    altura: Double;
    modo: LongInt;
    beta: Double;
  end;

  TResultadoCaida = record
    t_suelo: Double;
    v_suelo: Double;
    x_suelo: Double;
    pasos: LongInt;
  end;

function LeerEntrada(var e: TEntrada): Boolean;
begin
  Write('Modo (1=simular con beta, 2=buscar beta): ');
  ReadLn(e.modo);
  if (e.modo <> 1) and (e.modo <> 2) then
  begin
    WriteLn(StdErr, 'Modo invalido.');
    Exit(False);
  end;

  Write('Masa paracaidista (kg): ');
  ReadLn(e.masa_paracaidista);
  if e.masa_paracaidista <= 0.0 then
  begin
    WriteLn(StdErr, 'Masa paracaidista invalida.');
    Exit(False);
  end;

  Write('Masa impedimenta (kg): ');
  ReadLn(e.masa_impedimenta);
  if e.masa_impedimenta < 0.0 then
  begin
    WriteLn(StdErr, 'Masa impedimenta invalida.');
    Exit(False);
  end;

  Write('Altura de salto (m): ');
  ReadLn(e.altura);
  if e.altura <= 0.0 then
  begin
    WriteLn(StdErr, 'Altura invalida.');
    Exit(False);
  end;

  e.beta := 0.0;
  if e.modo = 1 then
  begin
    Write('Beta (N*s/m): ');
    ReadLn(e.beta);
    if e.beta <= 0.0 then
    begin
      WriteLn(StdErr, 'Beta invalida.');
      Exit(False);
    end;
  end;

  LeerEntrada := True;
end;

function PesoTotal(masa_paracaidista, masa_impedimenta, grav: Double): Double;
begin
  PesoTotal := (masa_paracaidista + masa_impedimenta) * grav;
end;

function FVelocidad(t, v, grav, beta, peso: Double): Double;
begin
  { t no entra en la EDO autonoma; se conserva por contrato }
  if t < -1.0e300 then
    FVelocidad := 0.0
  else
    FVelocidad := grav - (beta * grav / peso) * v;
end;

function PasoRK4(h, t, estado, grav, beta, peso: Double): Double;
var
  k1, k2, k3, k4: Double;
begin
  k1 := h * FVelocidad(t, estado, grav, beta, peso);
  k2 := h * FVelocidad(t + h / 2.0, estado + k1 / 2.0, grav, beta, peso);
  k3 := h * FVelocidad(t + h / 2.0, estado + k2 / 2.0, grav, beta, peso);
  k4 := h * FVelocidad(t + h, estado + k3, grav, beta, peso);
  PasoRK4 := estado + (k1 + 2.0 * k2 + 2.0 * k3 + k4) / 6.0;
end;

procedure PasoSistemaRK4(h, t, v, x, grav, beta, peso: Double;
  var v_out, x_out: Double);
var
  k1v, k1x, k2v, k2x, k3v, k3x, k4v, k4x: Double;
begin
  k1v := h * FVelocidad(t, v, grav, beta, peso);
  k1x := h * v;
  k2v := h * FVelocidad(t + h / 2.0, v + k1v / 2.0, grav, beta, peso);
  k2x := h * (v + k1v / 2.0);
  k3v := h * FVelocidad(t + h / 2.0, v + k2v / 2.0, grav, beta, peso);
  k3x := h * (v + k2v / 2.0);
  k4v := h * FVelocidad(t + h, v + k3v, grav, beta, peso);
  k4x := h * (v + k3v);

  v_out := PasoRK4(h, t, v, grav, beta, peso);
  x_out := x + (k1x + 2.0 * k2x + 2.0 * k3x + k4x) / 6.0;
  if Abs(k4v) < 0.0 then
    v_out := v_out;
end;

function VAnalitica(t, peso, beta, grav: Double): Double;
begin
  VAnalitica := (peso / beta) * (1.0 - Exp(-beta * grav * t / peso));
end;

function XAnalitica(t, peso, beta, grav: Double): Double;
begin
  XAnalitica := (peso / beta) * t
    + (peso / (beta * grav)) * Exp(-beta * grav * t / peso)
    - (peso / (beta * grav));
end;

function IntegrarCaida(peso, beta, altura, grav, h: Double; verbose: Boolean;
  var outRes: TResultadoCaida): Boolean;
var
  t, v, x, v_next, x_next, frac, t_s, v_s, x_s: Double;
  i: LongInt;
begin
  t := 0.0;
  v := 0.0;
  x := 0.0;

  if verbose then
  begin
    WriteLn;
    WriteLn(Format('%10s %12s %12s %12s %12s',
      ['t(s)', 'v(m/s)', 'x(m)', 'v_anal', 'x_anal']));
    WriteLn(Format('%10.2f %12.6f %12.6f %12.6f %12.6f',
      [t, v, x, VAnalitica(t, peso, beta, grav), XAnalitica(t, peso, beta, grav)]));
  end;

  for i := 0 to MAX_PASOS - 1 do
  begin
    PasoSistemaRK4(h, t, v, x, grav, beta, peso, v_next, x_next);

    if x_next >= altura then
    begin
      if Abs(x_next - x) < 1e-15 then
        frac := 0.0
      else
        frac := (altura - x) / (x_next - x);
      if frac < 0.0 then
        frac := 0.0;
      if frac > 1.0 then
        frac := 1.0;

      if h * frac > 1e-15 then
      begin
        PasoSistemaRK4(h * frac, t, v, x, grav, beta, peso, v_s, x_s);
        t_s := t + h * frac;
      end
      else
      begin
        v_s := v;
        x_s := x;
        t_s := t;
      end;

      outRes.t_suelo := t_s;
      outRes.v_suelo := v_s;
      outRes.x_suelo := x_s;
      outRes.pasos := i + 1;

      if verbose then
        WriteLn(Format('%10.2f %12.6f %12.6f %12.6f %12.6f   <-- suelo',
          [outRes.t_suelo, outRes.v_suelo, outRes.x_suelo,
           VAnalitica(outRes.t_suelo, peso, beta, grav),
           XAnalitica(outRes.t_suelo, peso, beta, grav)]));

      Exit(True);
    end;

    t := t + h;
    v := v_next;
    x := x_next;

    if verbose and (((i + 1) mod IMPRIMIR_CADA) = 0) then
      WriteLn(Format('%10.2f %12.6f %12.6f %12.6f %12.6f',
        [t, v, x, VAnalitica(t, peso, beta, grav), XAnalitica(t, peso, beta, grav)]));
  end;

  outRes.t_suelo := t;
  outRes.v_suelo := v;
  outRes.x_suelo := x;
  outRes.pasos := MAX_PASOS;
  IntegrarCaida := False;
end;

function VelocidadAlSuelo(peso, beta, altura, grav, h: Double): Double;
var
  r: TResultadoCaida;
begin
  IntegrarCaida(peso, beta, altura, grav, h, False, r);
  VelocidadAlSuelo := r.v_suelo;
end;

function BuscarBeta(peso, altura, grav, h, v_meta, tol_v: Double;
  var beta_out: Double; var verif: TResultadoCaida): Boolean;
var
  lo, hi, v_lo, v_hi, mid, v_mid: Double;
  iter: LongInt;
begin
  lo := BETA_LO;
  hi := BETA_HI;
  v_lo := VelocidadAlSuelo(peso, lo, altura, grav, h);
  v_hi := VelocidadAlSuelo(peso, hi, altura, grav, h);

  if (v_lo - v_meta) * (v_hi - v_meta) > 0.0 then
  begin
    WriteLn(StdErr, Format(
      'No hay cambio de signo en [%.1f, %.1f] (v_lo=%.4f, v_hi=%.4f, meta=%.4f).',
      [lo, hi, v_lo, v_hi, v_meta]));
    Exit(False);
  end;

  for iter := 1 to MAX_ITER_BETA do
  begin
    mid := 0.5 * (lo + hi);
    v_mid := VelocidadAlSuelo(peso, mid, altura, grav, h);

    if Abs(v_mid - v_meta) <= tol_v then
    begin
      beta_out := mid;
      IntegrarCaida(peso, mid, altura, grav, h, False, verif);
      Exit(True);
    end;

    if v_mid > v_meta then
      lo := mid
    else
      hi := mid;
  end;

  beta_out := 0.5 * (lo + hi);
  IntegrarCaida(peso, beta_out, altura, grav, h, False, verif);
  BuscarBeta := Abs(verif.v_suelo - v_meta) <= tol_v;
end;

procedure MostrarSalida(const e: TEntrada; peso, beta: Double;
  const r: TResultadoCaida; modo_busqueda: Boolean);
var
  v_kmh: Double;
begin
  v_kmh := r.v_suelo * 3.6;
  WriteLn;
  WriteLn('=== Resultado ===');
  WriteLn(Format('masas: %.2f + %.2f kg | W = %.4f N | H = %.2f m',
    [e.masa_paracaidista, e.masa_impedimenta, peso, e.altura]));
  if modo_busqueda then
  begin
    WriteLn(Format('beta encontrado: %.6f N*s/m', [beta]));
    WriteLn(Format('v_meta: %.6f m/s (%.3f km/h)', [V_META, V_META * 3.6]));
  end
  else
    WriteLn(Format('beta usado: %.6f N*s/m', [beta]));
  WriteLn(Format('t_suelo: %.4f s', [r.t_suelo]));
  WriteLn(Format('x_suelo: %.6f m', [r.x_suelo]));
  WriteLn(Format('v_suelo: %.6f m/s (%.3f km/h)', [r.v_suelo, v_kmh]));
  WriteLn(Format('pasos RK4: %d (h=%.2f s)', [r.pasos, H_PASO]));
end;

var
  e: TEntrada;
  r: TResultadoCaida;
  peso, beta: Double;
begin
  WriteLn('Proyecto uno: caida amortiguada (Pascal)');
  if not LeerEntrada(e) then
    Halt(1);

  peso := PesoTotal(e.masa_paracaidista, e.masa_impedimenta, G);
  beta := 0.0;

  if e.modo = 1 then
  begin
    beta := e.beta;
    if not IntegrarCaida(peso, beta, e.altura, G, H_PASO, True, r) then
    begin
      WriteLn(StdErr, Format('No se alcanzo el suelo en %d pasos.', [MAX_PASOS]));
      Halt(1);
    end;
    MostrarSalida(e, peso, beta, r, False);
  end
  else
  begin
    if not BuscarBeta(peso, e.altura, G, H_PASO, V_META, TOL_V, beta, r) then
    begin
      WriteLn(StdErr, 'No se encontro beta dentro de la tolerancia.');
      WriteLn(Format('Mejor aproximacion: beta=%.6f, v_suelo=%.6f m/s',
        [beta, r.v_suelo]));
      Halt(1);
    end;
    WriteLn;
    WriteLn(Format('Verificacion con beta=%.6f:', [beta]));
    if not IntegrarCaida(peso, beta, e.altura, G, H_PASO, True, r) then
    begin
      WriteLn(StdErr, 'No se alcanzo el suelo en la verificacion.');
      Halt(1);
    end;
    MostrarSalida(e, peso, beta, r, True);
  end;
end.
