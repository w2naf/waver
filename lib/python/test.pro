FUNCTION A_T,A_x,A_z,T_0,kappa,root,nu,gamma,omega,k_x
  """  
  [Francis, 1973] (Equation A21)
  """
  A_T = T_0*k_x/omega * ((A_x + kappa*A_z)/((1./(gamma-1.))-nu*root))
  return,A_T
END

FUNCTION A_p,A_x,A_z,A_T,T_0,p_0,kappa,root,alpha,nu,gamma,omega,k_x
  """  
  [Francis, 1973] (Equation A22)
  """
  A_p = p_0*k_x/omega * (A_x+A_z*(kappa-1j*alpha)) + p_0 * (A_T/T_0)
  return,A_T
END

PRO test

j = COMPLEX(0,1)
A_x = (0.051920979426297809+16.929225742024187*j)
A_z = (-16.971260494454029+0.024594187341625773*j)
T_0 = 710.5618896484375
kappa = (0.0013439868774567376+0.99962110711569441*j)
root = (0.0041377640614784555+0.0026824131680332763*j)
nu = 514.20853545650425*j
gamma = 1.5
omega = 0.1219228429175179
k_x = 0.0087766890011229618
p_0 = 4.5188867865379776e-05

A_T = A_T(A_x,A_z,T_0,kappa,root,nu,gamma,omega,k_x)
A_p = A_p(A_x,A_z,A_T,T_0,p_0,kappa,root,alpha,nu,gamma,omega,k_x)

STOP
END
