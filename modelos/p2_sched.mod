# =====================================================================
#  p2_sched.mod  ──  Parte 2: scheduling de carga (ENTREGABLE AMPL)
#  Minimizar el makespan con precedencia por camión y una bahía por producto.
#  Alineado 1:1 con p2_sched.py / datos_p2.py.
# =====================================================================

set OPS;                         # operaciones de carga: T1C0, T1C1, T2C0, T2C1
set PREC within {OPS, OPS};      # (i,j): i precede a j dentro del mismo camión (C0 antes de C1)
set CONF within {OPS, OPS};      # (i,j): comparten la misma bahía (no pueden solaparse)

param p {OPS};                   # tiempo de proceso (carga + limpieza) [min]
param M;                         # Big-M

var s {OPS} >= 0;                # tiempo de inicio de carga [min]
var Cmax >= 0;                   # makespan [min]
var y {CONF} binary;             # 1 si i precede a j en la bahía compartida

minimize Makespan: Cmax;

# Precedencia dentro del camión: C1 empieza cuando C0 termina
s.t. Precedencia {(i,j) in PREC}: s[j] >= s[i] + p[i];

# No-solapamiento en la misma bahía (disyuntiva big-M)
s.t. Bahia_a {(i,j) in CONF}: s[j] >= s[i] + p[i] - M*(1 - y[i,j]);
s.t. Bahia_b {(i,j) in CONF}: s[i] >= s[j] + p[j] - M*y[i,j];

# Makespan
s.t. Cota {o in OPS}: Cmax >= s[o] + p[o];
