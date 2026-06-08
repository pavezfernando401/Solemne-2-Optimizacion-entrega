# =====================================================================
#  p1_routing.mod  ──  Parte 1: MILP determinista (ENTREGABLE AMPL)
#  Alineado 1:1 con p1_routing.py / datos.py.
#  Variables: r, z, w, u, x, q, arr, sal, FR, sh.
# =====================================================================

# ---------- Conjuntos ----------
set NODOS;                       # 0 = depósito, 1..4 = estaciones
set CLI within NODOS;            # estaciones (clientes)
set K;                           # camiones
set COMP;                        # compartimentos {0,1}
set PROD;                        # productos {R,D}
set ARCS := {i in NODOS, j in NODOS: i <> j};

# ---------- Parámetros ----------
param cd;                        # $/km
param cs;                        # $/L de faltante
param F {K};                     # costo fijo del camión
param Q {K,COMP};                # capacidad de compartimento [L]
param Dem {CLI,PROD};            # demanda [L]
param a {CLI};                   # apertura ventana [min]
param b {CLI};                   # cierre ventana   [min]
param tserv;                     # tiempo de servicio [min]
param v;                         # velocidad [km/min]
param dep {K};                   # salida del depósito [min]
param dist {ARCS};               # distancia [km]
param DELTA;                     # tolerancia de estabilidad
param Mfr;                       # Big-M fill ratio (≈2)
param Mt;                        # Big-M tiempo (≈2000)
param t {(i,j) in ARCS} := dist[i,j] / v;     # tiempo de viaje [min]
param n := card(CLI);

# ---------- Variables ----------
var r {ARCS,K} binary;                 # arco (i,j) usado por k
var z {K} binary;                      # camión usado
var w {K,COMP,PROD} binary;            # producto p en compartimento (k,c)
var u {CLI,K} integer >= 0;            # posición MTZ
var x {K,COMP,PROD} >= 0;              # carga total [L]
var q {CLI,K,COMP,PROD} >= 0;          # entregado en j desde (k,c) [L]
var arr {CLI,K} >= 0;                  # hora de llegada [min]
var sal {CLI,K} >= 0;                  # hora de salida  [min]
var FR {K,COMP,NODOS} >= 0, <= 1;      # fill ratio al salir del nodo
var sh {CLI,PROD} >= 0;                # faltante [L]

# ---------- Función objetivo ----------
minimize Costo:
    cd * sum {(i,j) in ARCS, k in K} dist[i,j] * r[i,j,k]
  + sum {k in K} F[k] * z[k]
  + cs * sum {j in CLI, p in PROD} sh[j,p];

# ---------- (R) Conservación de flujo ----------
s.t. R1_sale {k in K}:   sum {l in CLI} r[0,l,k] = z[k];
s.t. R1_vuelve {k in K}: sum {j in CLI} r[j,0,k] = z[k];
s.t. R2_balance {j in NODOS, k in K}:
     sum {i in NODOS: i<>j} r[i,j,k] = sum {l in NODOS: l<>j} r[j,l,k];
s.t. R3_unCamion {j in CLI}:
     sum {k in K, i in NODOS: i<>j} r[i,j,k] <= 1;

# ---------- (S) Subtours MTZ ----------
s.t. S1 {j in CLI, l in CLI, k in K: j<>l}:
     u[j,k] - u[l,k] + n * r[j,l,k] <= n - 1;

# ---------- (D) Demanda con shortage ----------
s.t. D1 {j in CLI, p in PROD}:
     sum {k in K, c in COMP} q[j,k,c,p] + sh[j,p] = Dem[j,p];

# ---------- (C) Compatibilidad compartimento-producto ----------
s.t. C1 {k in K, c in COMP}: sum {p in PROD} w[k,c,p] <= 1;
s.t. C2 {j in CLI, k in K, c in COMP, p in PROD}: q[j,k,c,p] <= Q[k,c] * w[k,c,p];
s.t. C3 {j in CLI, k in K, c in COMP, p in PROD}:
     q[j,k,c,p] <= Q[k,c] * sum {i in NODOS: i<>j} r[i,j,k];

# ---------- (K) Capacidad ----------
s.t. K1 {k in K, c in COMP, p in PROD}: x[k,c,p] = sum {j in CLI} q[j,k,c,p];
s.t. K2 {k in K, c in COMP}: sum {p in PROD} x[k,c,p] <= Q[k,c];

# ---------- (E) Estabilidad de carga (fill ratio) ----------
s.t. E1 {k in K, c in COMP}:
     FR[k,c,0] = ( sum {p in PROD} x[k,c,p] ) / Q[k,c];
s.t. E2 {(i,j) in ARCS, k in K, c in COMP: j in CLI}:
     FR[k,c,j] >= FR[k,c,i] - ( sum {p in PROD} q[j,k,c,p] )/Q[k,c] - Mfr*(1 - r[i,j,k]);
s.t. E3 {(i,j) in ARCS, k in K, c in COMP: j in CLI}:
     FR[k,c,j] <= FR[k,c,i] - ( sum {p in PROD} q[j,k,c,p] )/Q[k,c] + Mfr*(1 - r[i,j,k]);
s.t. E4a {j in NODOS, k in K}: FR[k,0,j] - FR[k,1,j] <= DELTA;
s.t. E4b {j in NODOS, k in K}: FR[k,1,j] - FR[k,0,j] <= DELTA;

# ---------- (T) Ventanas de tiempo (con espera permitida) ----------
s.t. T1 {l in CLI, k in K}:
     arr[l,k] >= dep[k] + t[0,l] - Mt*(1 - r[0,l,k]);
s.t. T2 {j in CLI, l in CLI, k in K: j<>l}:
     arr[l,k] >= sal[j,k] + t[j,l] - Mt*(1 - r[j,l,k]);
s.t. T3a {j in CLI, k in K}: sal[j,k] >= arr[j,k] + tserv;
s.t. T3b {j in CLI, k in K}:
     sal[j,k] >= a[j] + tserv - Mt*(1 - sum {i in NODOS: i<>j} r[i,j,k]);
s.t. T4 {j in CLI, k in K}:
     arr[j,k] <= b[j] + Mt*(1 - sum {i in NODOS: i<>j} r[i,j,k]);
