// Closed-form walk-away point, shared by the decision-map slider and the JS-R parity diagnostic.
// p holds the inputs named as in params.yaml (c, T_r, b, T_fail, q, T_d, d_pay, s, kappa, K_pay, K_leak, p_np, p_p).

export function expectedT(p) {
  return p.b * p.T_r + (1 - p.b) * p.T_fail;
}

export function walkAway(p) {
  return (p.c * (p.q * (expectedT(p) - p.T_d) - p.d_pay) + (p.p_np - p.p_p) * p.K_leak - p.K_pay) /
    (1 + p.s * p.kappa);
}

// Restore time at which the walk-away point reaches zero
export function neverPayRestore(p) {
  const num = ((p.K_pay - (p.p_np - p.p_p) * p.K_leak) / p.c + p.d_pay) / p.q + p.T_d - (1 - p.b) * p.T_fail;
  return num / p.b;
}
