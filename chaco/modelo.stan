data {
  int<lower=1> Mesas;
  int<lower=1> Circuitos;
  int<lower=1> Partidos;
  real votos[Mesas, Partidos];
  int<lower=1, upper=Circuitos> circuito[Mesas];
  int<lower=0, upper=1> electronica[Mesas];
}
parameters {
  real a[Circuitos, Partidos];
  matrix[Partidos, Circuitos] z;
  vector[Partidos] beta;
  real<lower=0> sigma[Partidos];
  cholesky_factor_corr[Partidos] L_Omega;
  vector<lower=0>[Partidos] S_Omega;
}
transformed parameters {
  matrix[Circuitos, Partidos] b;
  for(c in 1:Circuitos)
    for(j in 1:Partidos)
      b[c, j] = beta[j];
  b = b + (diag_pre_multiply(S_Omega, L_Omega) * z)';
}
model {
  for(i in 1:Mesas)
    for(j in 1:Partidos)
      votos[i, j] ~ normal(a[circuito[i], j] + b[circuito[i], j] * electronica[i], sigma[j]);
  to_vector(z) ~ normal(0, 1);
  L_Omega ~ lkj_corr_cholesky(2);
  for(c in 1:Circuitos) a[c, ] ~ normal(0.5, 0.5);
  beta ~ cauchy(0, 1);
  sigma ~ cauchy(0, 1);
  S_Omega ~ normal(0, 1);
}
generated quantities {
  vector[Partidos] b_ = multi_normal_cholesky_rng(beta, diag_pre_multiply(S_Omega, L_Omega));
}
