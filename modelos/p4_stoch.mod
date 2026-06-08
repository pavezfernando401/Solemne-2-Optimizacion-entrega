# =====================================================================
#  p4_stoch.mod  ──  Parte 4: estocástico de DOS ETAPAS (ENTREGABLE AMPL)
#  Forma extensiva (todos los escenarios juntos).
#  1ª etapa: r, z, w, u, x, arr, sal   (no dependen del escenario)
#  2ª etapa: q[s], sh[s], FR[s]        (recurso, una copia por escenario)
# =====================================================================

# ---------- Conjuntos ----------
set NODOS;  set CLI within NODOS;  set K;  set COMP;  set PROD;
set S;                                     # escenarios
set ARCS := {i in NODOS, j in NODOS: i <> j};

# ---------- Parámetros ----------
param cd;  param cs;  param tserv;  param v;  param DELTA;  param Mfr;  param Mt;
param F {K};  param Q {K,COMP};  param dep {K};
param a {CLI};  param b {CLI};   param dist {ARCS};
param prob {S};                            # probabilidad del escenario
param Dem {S,CLI,PROD};                    # demanda por escenario
param t {(i,j) in ARCS} := dist[i,j]/v;
param n := card(CLI);

# ---------- Variables de 1ª etapa ----------
var r {ARCS,K} binary;
var z {K} binary;
var w {K,COMP,PROD} binary;
var u {CLI,K} integer >= 0;
var x {K,COMP,PROD} >= 0;                   # CARGA (se decide antes de la demanda)
var arr {CLI,K} >= 0;
var sal {CLI,K} >= 0;

# ---------- Variables de 2ª etapa (recurso, por escenario) ----------
var q  {S,CLI,K,COMP,PROD} >= 0;           # entregas por escenario
var sh {S,CLI,PROD} >= 0;                   # faltante por escenario
var FR {S,K,COMP,NODOS} >= 0, <= 1;

# ---------- Objetivo: 1ª etapa + faltante ESPERADO ----------
minimize CostoEsperado:
    cd * sum {(i,j) in ARCS, k in K} dist[i,j]*r[i,j,k]
  + sum {k in K} F[k]*z[k]
  + sum {s in S} prob[s] * cs * sum {j in CLI, p in PROD} sh[s,j,p];

# ===================== 1ª ETAPA =====================
s.t. R1_sale {k in K}:   sum {l in CLI} r[0,l,k] = z[k];
s.t. R1_vuelve {k in K}: sum {j in CLI} r[j,0,k] = z[k];
s.t. R2 {j in NODOS, k in K}:
     sum {i in NODOS: i<>j} r[i,j,k] = sum {l in NODOS: l<>j} r[j,l,k];
s.t. R3 {j in CLI}: sum {k in K, i in NODOS: i<>j} r[i,j,k] <= 1;
s.t. S1 {j in CLI, l in CLI, k in K: j<>l}: u[j,k]-u[l,k]+n*r[j,l,k] <= n-1;

s.t. C1 {k in K, c in COMP}: sum {p in PROD} w[k,c,p] <= 1;
s.t. Cap {k in K, c in COMP}: sum {p in PROD} x[k,c,p] <= Q[k,c];
s.t. CargaProd {k in K, c in COMP, p in PROD}: x[k,c,p] <= Q[k,c]*w[k,c,p];

s.t. T1 {l in CLI, k in K}: arr[l,k] >= dep[k] + t[0,l] - Mt*(1 - r[0,l,k]);
s.t. T2 {j in CLI, l in CLI, k in K: j<>l}: arr[l,k] >= sal[j,k] + t[j,l] - Mt*(1 - r[j,l,k]);
s.t. T3a {j in CLI, k in K}: sal[j,k] >= arr[j,k] + tserv;
s.t. T3b {j in CLI, k in K}: sal[j,k] >= a[j] + tserv - Mt*(1 - sum {i in NODOS: i<>j} r[i,j,k]);
s.t. T4 {j in CLI, k in K}: arr[j,k] <= b[j] + Mt*(1 - sum {i in NODOS: i<>j} r[i,j,k]);

# ===================== 2ª ETAPA (por escenario) =====================
s.t. Demanda {s in S, j in CLI, p in PROD}:
     sum {k in K, c in COMP} q[s,j,k,c,p] + sh[s,j,p] = Dem[s,j,p];
s.t. NoMasQueCargado {s in S, k in K, c in COMP}:
     sum {j in CLI, p in PROD} q[s,j,k,c,p] <= sum {p in PROD} x[k,c,p];
s.t. SoloProd {s in S, j in CLI, k in K, c in COMP, p in PROD}: q[s,j,k,c,p] <= Q[k,c]*w[k,c,p];
s.t. SoloVisita {s in S, j in CLI, k in K, c in COMP, p in PROD}:
     q[s,j,k,c,p] <= Q[k,c] * sum {i in NODOS: i<>j} r[i,j,k];

s.t. E1 {s in S, k in K, c in COMP}: FR[s,k,c,0] = ( sum {p in PROD} x[k,c,p] )/Q[k,c];
s.t. E2 {s in S, (i,j) in ARCS, k in K, c in COMP: j in CLI}:
     FR[s,k,c,j] >= FR[s,k,c,i] - ( sum {p in PROD} q[s,j,k,c,p] )/Q[k,c] - Mfr*(1 - r[i,j,k]);
s.t. E3 {s in S, (i,j) in ARCS, k in K, c in COMP: j in CLI}:
     FR[s,k,c,j] <= FR[s,k,c,i] - ( sum {p in PROD} q[s,j,k,c,p] )/Q[k,c] + Mfr*(1 - r[i,j,k]);
s.t. E4a {s in S, j in NODOS, k in K}: FR[s,k,0,j] - FR[s,k,1,j] <= DELTA;
s.t. E4b {s in S, j in NODOS, k in K}: FR[s,k,1,j] - FR[s,k,0,j] <= DELTA;
