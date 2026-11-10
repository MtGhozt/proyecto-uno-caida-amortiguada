{ Caida amortiguada de un paracaidista - implementacion en Pascal (Free Pascal)
  IC4700 Lenguajes de Programacion - Proyecto programado 1

  Resuelve  (W/g) dv/dt = W - beta*v,  v(0) = 0,  junto con dx/dt = v,
  mediante Runge-Kutta de 4.o orden, hasta que el paracaidista llega al
  suelo (x >= altura). En modo 2 busca por biseccion el valor de beta que
  produce una velocidad de aterrizaje de ~8 km/h.

  Diseno: docs/algoritmo.md y docs/nassi-schneiderman/ (un diagrama por
  procedimiento/funcion; los nombres y parametros coinciden con los diagramas).
  Programacion estructurada: cada subprograma tiene una sola entrada y una
  sola salida (sin Exit/Break); comunicacion solo por parametros.

  Compilar:  fpc -O2 main.pas }

{$mode objfpc}
{$H+}

program CaidaAmortiguada;

uses
  SysUtils;

{ ---- Constantes congeladas (docs/algoritmo.md) ---- }
const
  G = 9.81;                 { gravedad [m/s^2] }
  H_PASO = 0.1;             { paso RK4 [s] }
  V_META = 20.0 / 9.0;      { 8 km/h en m/s }
  TOL_V = 0.05;             { tolerancia de v_suelo [m/s] }
  BETA_LO = 1.0;            { extremo inferior de la biseccion [N*s/m] }
  Z_ESTABLE = 2.0;          { beta_hi = Z_ESTABLE*W/(g*h): RK4 estable }
  MAX_ITER_BETA = 60;       { iteraciones maximas de biseccion }
  IMPRIMIR_CADA = 50;       { una fila de tabla cada 50 pasos }
  MAX_PASOS = 200000;       { pasos maximos por simulacion }
  MAX_FILAS = MAX_PASOS div IMPRIMIR_CADA + 2;

{ ---- Registros ---- }
type
  TEntrada = record
    modo: LongInt;                 { 1 = beta dado, 2 = buscar beta }
    masa_paracaidista: Double;     { [kg] }
    masa_impedimenta: Double;      { [kg] }
    altura: Double;                { [m] }
    beta: Double;                  { [N*s/m] (solo modo 1) }
  end;

  TFila = record
    t, v, x: Double;               { [s], [m/s], [m] }
  end;

  TResultadoCaida = record
    aterrizo: Boolean;             { verdadero si se alcanzo x >= altura }
    t_suelo: Double;               { instante de aterrizaje [s] }
    v_suelo: Double;               { velocidad de aterrizaje [m/s] }
    x_suelo: Double;               { distancia recorrida al aterrizar [m] }
    pasos: LongInt;                { pasos RK4 realizados }
    n_filas: LongInt;              { filas usadas en la tabla }
    filas: array[1..MAX_FILAS] of TFila;
  end;

{ leer_entrada
  Funcionalidad: pedir y validar modo, masa del paracaidista, masa de la
    impedimenta, altura y (solo en modo 1) beta. Una lectura no numerica se
    considera un valor invalido.
  Entradas: datos del teclado.
  Salidas: e (registro TEntrada); ok = True si todos los datos son validos. }
procedure leer_entrada(var e: TEntrada; var ok: Boolean);
var
  campo, linea: String;
  cod: Integer;
begin
  campo := 'modo';
  Write('Modo (1=simular con beta, 2=buscar beta): ');
  ReadLn(linea);
  Val(Trim(linea), e.modo, cod);
  ok := (cod = 0) and ((e.modo = 1) or (e.modo = 2));
  e.beta := 0.0;

  if ok then
  begin
    campo := 'masa del paracaidista';
    Write('Masa paracaidista (kg): ');
    ReadLn(linea);
    Val(Trim(linea), e.masa_paracaidista, cod);
    ok := (cod = 0) and (e.masa_paracaidista > 0.0);
  end;
  if ok then
  begin
    campo := 'masa de la impedimenta';
    Write('Masa impedimenta (kg): ');
    ReadLn(linea);
    Val(Trim(linea), e.masa_impedimenta, cod);
    ok := (cod = 0) and (e.masa_impedimenta >= 0.0);
  end;
  if ok then
  begin
    campo := 'altura';
    Write('Altura de salto (m): ');
    ReadLn(linea);
    Val(Trim(linea), e.altura, cod);
    ok := (cod = 0) and (e.altura > 0.0);
  end;
  if ok and (e.modo = 1) then
  begin
    campo := 'beta';
    Write('Beta (N*s/m): ');
    ReadLn(linea);
    Val(Trim(linea), e.beta, cod);
    ok := (cod = 0) and (e.beta > 0.0);
  end;
  if not ok then
    WriteLn(StdErr, 'Valor invalido: ', campo);
end;

{ peso_total
  Funcionalidad: peso combinado W = (masa_paracaidista + masa_impedimenta) * g.
  Entradas: masa_paracaidista [kg], masa_impedimenta [kg], g [m/s^2].
  Salida: W [N]. }
function peso_total(masa_paracaidista, masa_impedimenta, g: Double): Double;
begin
  peso_total := (masa_paracaidista + masa_impedimenta) * g;
end;

{ f_velocidad
  Funcionalidad: lado derecho de la EDO, dv/dt = g - (beta*g/W)*v.
    La EDO es autonoma (no depende de t).
  Entradas: v [m/s], g [m/s^2], beta [N*s/m], W [N].
  Salida: dv/dt [m/s^2]. }
function f_velocidad(v, g, beta, W: Double): Double;
begin
  f_velocidad := g - (beta * g / W) * v;
end;

{ paso_rk4
  Funcionalidad: un paso de Runge-Kutta 4 del sistema acoplado
    v' = f_velocidad(v), x' = v.
  Entradas: h [s], v [m/s], x [m], g, beta, W (parametros de f_velocidad).
  Salidas: v_sig, x_sig (estado despues del paso h). }
procedure paso_rk4(h, v, x, g, beta, W: Double; var v_sig, x_sig: Double);
var
  k1v, k1x, k2v, k2x, k3v, k3x, k4v, k4x: Double;
begin
  k1v := h * f_velocidad(v, g, beta, W);
  k1x := h * v;
  k2v := h * f_velocidad(v + k1v / 2.0, g, beta, W);
  k2x := h * (v + k1v / 2.0);
  k3v := h * f_velocidad(v + k2v / 2.0, g, beta, W);
  k3x := h * (v + k2v / 2.0);
  k4v := h * f_velocidad(v + k3v, g, beta, W);
  k4x := h * (v + k3v);

  v_sig := v + (k1v + 2.0 * k2v + 2.0 * k3v + k4v) / 6.0;
  x_sig := x + (k1x + 2.0 * k2x + 2.0 * k3x + k4x) / 6.0;
end;

{ registrar_fila
  Funcionalidad: agregar la fila (t, v, x) a la tabla de r, si hay capacidad.
  Entradas: r, t [s], v [m/s], x [m].
  Salidas: r.filas y r.n_filas actualizados. }
procedure registrar_fila(var r: TResultadoCaida; t, v, x: Double);
begin
  if r.n_filas < MAX_FILAS then
  begin
    r.n_filas := r.n_filas + 1;
    r.filas[r.n_filas].t := t;
    r.filas[r.n_filas].v := v;
    r.filas[r.n_filas].x := x;
  end;
end;

{ integrar_caida
  Funcionalidad: integrar la caida con paso_rk4 desde el reposo hasta que
    x >= altura; el ultimo paso se recorta a h*frac para estimar el instante
    y la velocidad de aterrizaje. Guarda la tabla (fila inicial, cada
    IMPRIMIR_CADA pasos y la de aterrizaje).
    Invariante del ciclo: x < altura, por lo que x_sig - x > 0 y frac en (0, 1].
  Entradas: W [N], beta [N*s/m], altura [m], g [m/s^2], h [s].
  Salidas: r (aterrizo, t_suelo, v_suelo, x_suelo, pasos, tabla). }
procedure integrar_caida(W, beta, altura, g, h: Double; var r: TResultadoCaida);
var
  t, v, x, v_sig, x_sig, frac: Double;
  i: LongInt;
  aterrizo: Boolean;
begin
  t := 0.0;
  v := 0.0;
  x := 0.0;
  i := 0;
  aterrizo := False;
  r.n_filas := 0;
  registrar_fila(r, t, v, x);

  while (not aterrizo) and (i < MAX_PASOS) do
  begin
    paso_rk4(h, v, x, g, beta, W, v_sig, x_sig);
    if x_sig >= altura then
    begin
      frac := (altura - x) / (x_sig - x);
      paso_rk4(h * frac, v, x, g, beta, W, v_sig, x_sig);
      t := t + h * frac;
      aterrizo := True;
    end
    else
      t := t + h;
    v := v_sig;
    x := x_sig;
    i := i + 1;
    if aterrizo or (i mod IMPRIMIR_CADA = 0) then
      registrar_fila(r, t, v, x);
  end;

  r.aterrizo := aterrizo;
  r.t_suelo := t;
  r.v_suelo := v;
  r.x_suelo := x;
  r.pasos := i;
end;

{ buscar_beta
  Funcionalidad: hallar beta por biseccion tal que
    |v_suelo(beta) - v_meta| <= tol_v. Mas beta => menor v_suelo.
    hi = Z_ESTABLE*W/(g*h) mantiene |h*lambda| = 2 < 2.785 (RK4 estable).
  Entradas: W [N], altura [m], g [m/s^2], h [s], v_meta [m/s], tol_v [m/s].
  Salidas: beta (encontrado o mejor aproximacion) [N*s/m];
           encontrado = True si se cumplio la tolerancia. }
procedure buscar_beta(W, altura, g, h, v_meta, tol_v: Double;
  var beta: Double; var encontrado: Boolean);
var
  r: TResultadoCaida;
  lo, hi, v_lo, v_hi: Double;
  iter: LongInt;
begin
  lo := BETA_LO;
  hi := Z_ESTABLE * W / (g * h);
  integrar_caida(W, lo, altura, g, h, r);
  v_lo := r.v_suelo;
  integrar_caida(W, hi, altura, g, h, r);
  v_hi := r.v_suelo;
  encontrado := False;
  iter := 0;
  beta := (lo + hi) / 2.0;

  if (v_lo - v_meta) * (v_hi - v_meta) <= 0.0 then
    while (not encontrado) and (iter < MAX_ITER_BETA) do
    begin
      beta := (lo + hi) / 2.0;
      integrar_caida(W, beta, altura, g, h, r);
      if Abs(r.v_suelo - v_meta) <= tol_v then
        encontrado := True
      else if r.v_suelo > v_meta then
        lo := beta
      else
        hi := beta;
      iter := iter + 1;
    end;
end;

{ v_analitica
  Funcionalidad: velocidad analitica v(t) = (W/beta)*(1 - exp(-beta*g*t/W)).
  Entradas: t [s], W [N], beta [N*s/m], g [m/s^2].
  Salida: v(t) [m/s]. }
function v_analitica(t, W, beta, g: Double): Double;
begin
  v_analitica := (W / beta) * (1.0 - Exp(-beta * g * t / W));
end;

{ x_analitica
  Funcionalidad: distancia analitica
    x(t) = (W/beta)*t + (W/(beta*g))*exp(-beta*g*t/W) - W/(beta*g).
  Entradas: t [s], W [N], beta [N*s/m], g [m/s^2].
  Salida: x(t) [m]. }
function x_analitica(t, W, beta, g: Double): Double;
begin
  x_analitica := (W / beta) * t + (W / (beta * g)) * Exp(-beta * g * t / W)
    - W / (beta * g);
end;

{ mostrar_tabla
  Funcionalidad: imprimir la tabla numerica (t, v, x) junto a la solucion
    analitica, marcando la fila de aterrizaje.
  Entradas: r (tabla), W [N], beta [N*s/m], g [m/s^2].
  Salidas: ninguna (pantalla). }
procedure mostrar_tabla(const r: TResultadoCaida; W, beta, g: Double);
var
  k: LongInt;
begin
  WriteLn;
  WriteLn(Format('%10s %12s %12s %12s %12s', ['t(s)', 'v(m/s)', 'x(m)', 'v_anal', 'x_anal']));
  for k := 1 to r.n_filas do
  begin
    Write(Format('%10.2f %12.6f %12.6f %12.6f %12.6f',
      [r.filas[k].t, r.filas[k].v, r.filas[k].x,
       v_analitica(r.filas[k].t, W, beta, g),
       x_analitica(r.filas[k].t, W, beta, g)]));
    if r.aterrizo and (k = r.n_filas) then
      Write('   [suelo]');
    WriteLn;
  end;
end;

{ mostrar_salida
  Funcionalidad: imprimir el resumen de resultados; el texto de beta
    depende de e.modo.
  Entradas: e, W [N], beta [N*s/m], r, h [s], v_meta [m/s].
  Salidas: ninguna (pantalla). }
procedure mostrar_salida(const e: TEntrada; W, beta: Double;
  const r: TResultadoCaida; h, v_meta: Double);
begin
  WriteLn;
  WriteLn('=== Resultado ===');
  WriteLn(Format('masas: %.2f + %.2f kg | W = %.4f N | H = %.2f m',
    [e.masa_paracaidista, e.masa_impedimenta, W, e.altura]));
  if e.modo = 2 then
  begin
    WriteLn(Format('beta encontrado: %.6f N*s/m', [beta]));
    WriteLn(Format('v_meta: %.6f m/s (%.3f km/h)', [v_meta, v_meta * 3.6]));
  end
  else
    WriteLn(Format('beta usado: %.6f N*s/m', [beta]));
  WriteLn(Format('t_suelo: %.4f s', [r.t_suelo]));
  WriteLn(Format('x_suelo: %.6f m', [r.x_suelo]));
  WriteLn(Format('v_suelo: %.6f m/s (%.3f km/h)', [r.v_suelo, r.v_suelo * 3.6]));
  WriteLn(Format('pasos RK4: %d (h = %.2f s)', [r.pasos, h]));
end;

{ Programa principal
  Funcionalidad: dirigir el flujo del programa segun el modo elegido.
  Entradas: ninguna (los datos los lee leer_entrada).
  Salida: codigo de salida (0 exito, 1 error). }
var
  e: TEntrada;
  r: TResultadoCaida;
  W, beta: Double;
  ok, encontrado: Boolean;
  codigo: LongInt;
begin
  { Format/Val usan '.' como separador decimal en cualquier configuracion regional }
  DefaultFormatSettings.DecimalSeparator := '.';
  WriteLn('Proyecto uno: caida amortiguada (Pascal)');
  leer_entrada(e, ok);
  if ok then
  begin
    W := peso_total(e.masa_paracaidista, e.masa_impedimenta, G);
    if e.modo = 1 then
    begin
      beta := e.beta;
      encontrado := True;
    end
    else
    begin
      buscar_beta(W, e.altura, G, H_PASO, V_META, TOL_V, beta, encontrado);
      if not encontrado then
        WriteLn('Aviso: no se alcanzo TOL_V; se usa la mejor aproximacion');
    end;
    integrar_caida(W, beta, e.altura, G, H_PASO, r);
    if r.aterrizo then
    begin
      mostrar_tabla(r, W, beta, G);
      mostrar_salida(e, W, beta, r, H_PASO, V_META);
      codigo := 0;
    end
    else
    begin
      WriteLn(StdErr, 'Sin aterrizaje: no se alcanzo el suelo en ', MAX_PASOS, ' pasos');
      codigo := 1;
    end;
  end
  else
    codigo := 1;
  ExitCode := codigo;
end.
