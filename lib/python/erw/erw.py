# coding=utf-8
import datetime
import collections

from matplotlib import pyplot as mp
import numpy as np
import scipy as sp

g     = 8.83 # m s^{-2}
gamma = 1.5
R_gas = 8.3144621     #Ideal gas constant [J / (mol K)]

def get_iterable(x):
    if isinstance(x, collections.Iterable):
        return x
    else:
        return (x,)

def get_index(value,vector):
    """Return index of a vector that is closest to the provided value.
    """
    inx = np.where(vector >= value)
    if np.size(inx) > 0:
      inx = inx[0][0]
    else: inx = -1
    return inx

class ns_functions(object):
    """Functions used for solving the Navier-Stokes Equations
    [Francis, 1973], Appendix
    """
    def alpha(self,k_x,H):
      """
      k_x:      Horizontal wave number [rad/m]
      H:        Scale height [m]
      [Francis, 1973] (Equation A5)
      """
      alpha = 1./(k_x*H)
      return alpha

    def beta(self,omega,g,k_x,H):
      """
      omega:    Angular wave frequency [rad/s]
      g:        Gravitational acceleration [m/(s**2)]
      k_x:      Horizontal wave number [rad/m]
      H:        Scale height [m]
      [Francis, 1973] (Equation A6)
      """
      beta = omega**2 / (g* k_x**2 * H)
      return beta

    def eta(self,omega,mu,p_0):
      """
      omega:    Angular wave frequency [rad/s]
      mu:       Coefficient of viscocity [kg/(m*sec)]
      p_0:      Ambienty pressure [Pa = kg/(m*sec**2)
      [Francis, 1973] (Equation A7)
      """
      eta = (1j * omega * mu) / (3.*p_0)
      return eta

    def nu(self,lambda_th,T_0,k_x,omega,p_0):
      """
      lambda_th:  Coefficient of thermal conductivty [(kg*m)/(K*sec**3)]
      T_0:        Ambient temperature [K]
      k_x:        Horizontal wave number [rad/m]
      omega:      Angular wave frequency [rad/s]
      p_0:        Ambienty pressure [Pa = kg/(m*sec**2)
      [Francis, 1973] (Equation A8)
      """
      nu = (1j*lambda_th*T_0*k_x**2)/(omega*p_0)
      return nu

    def sigma(self,sigma_p,B,rho_0,omega):
      """
      sigma_p:    Pedersen Conductivity [Si/m]
      B:          Magnetic Field [T]
      rho_0:      Mass density [kg/m**3]
      omega:      Angular wave frequency [rad/s]
      [Francis, 1973] (Equation A9)
      """
      sigma = (sigma_p*B**2)/(rho_0*omega)
      return sigma

    def C3(self,eta,nu):
      """
      eta: Non-dimensional paramater [Francis, 1973] (Equation A7)
      nu:  Non-dimensional paramater [Francis, 1973] (Equation A8)
      [Francis, 1973] (Equation A11)
      """
      C3 = -3.*eta*nu*(1.+4.*eta)
      return C3

    def C2(self,beta,eta,nu,sigma,b1,b3,gamma):
      """
      beta:   Non-dimensional paramater [Francis, 1973] (Equation A6)
      eta:    Non-dimensional paramater [Francis, 1973] (Equation A7)
      nu:     Non-dimensional paramater [Francis, 1973] (Equation A8)
      sigma:  Non-dimensional paramater [Francis, 1973] (Equation A9)
      b1:     I need to find out what this parameter is; it seems to be related to ion drag.
      b3:     I need to find out what this parameter is; it seems to be related to ion drag.
      [Francis, 1973] (Equation A12)
      """
      C2 = (
              (3.*eta*(1.+4.*eta)) / (gamma-1.)
            + nu*beta*(1.+7.*eta)
            + 3.*eta - 1j*sigma*beta*nu*( (1.+4.*eta)*(1.-b1**2)
              + 3.*eta*(1.-b3**2))
            )
      return C2

    def C1(self,alpha,beta,eta,nu,sigma,b1,b3,gamma):
      """
      alpha:  Non-dimensional paramater [Francis, 1973] (Equation A5)
      beta:   Non-dimensional paramater [Francis, 1973] (Equation A6)
      eta:    Non-dimensional paramater [Francis, 1973] (Equation A7)
      nu:     Non-dimensional paramater [Francis, 1973] (Equation A8)
      sigma:  Non-dimensional paramater [Francis, 1973] (Equation A9)
      b1:     I need to find out what this parameter is; it seems to be related to ion drag.
      b3:     I need to find out what this parameter is; it seems to be related to ion drag.
      [Francis, 1973] (Equation A13)
      """
      C1 = (
              -(beta**2 - 2.*eta*alpha**2*(1.+3.*eta))*nu
             - (beta*(1.+7*eta))/(gamma-1.) - beta
             + 1j*sigma*beta*(1.-b1**2) * (
                (gamma+4.*eta)/(gamma-1.)
              + nu*(1. + eta + beta))
             + 1j*sigma*beta*(1.-b3**2) * (
                (3.*eta)/(gamma-1)
              - nu*(1. + eta - beta))
             )
      return C1

    def C0(self,alpha,beta,eta,sigma,b1,b3,gamma):
      """
      alpha:  Non-dimensional paramater [Francis, 1973] (Equation A5)
      beta:   Non-dimensional paramater [Francis, 1973] (Equation A6)
      eta:    Non-dimensional paramater [Francis, 1973] (Equation A7)
      sigma:  Non-dimensional paramater [Francis, 1973] (Equation A9)
      b1:     I need to find out what this parameter is; it seems to be related to ion drag.
      b3:     I need to find out what this parameter is; it seems to be related to ion drag.
      [Francis, 1973] (Equation A14)
      """
      C0 = (
              (beta**2 - 2.*eta*alpha**2*(1.+3.*eta))/(gamma-1.)
            + alpha**2 * (1.+3**eta)
            + (1j*sigma*beta)/(gamma-1.) * (
                (1.-b3**2)*(gamma+eta-beta)
              - (1.-b1**2)*(gamma+eta+beta)
              )
            )
      return C0

    def A_x(self,kappa,root,alpha,beta,eta,nu,sigma,b1,b3,gamma,omega,k_x):
      """
      [Francis, 1973] (Equation A19)
      """
      A_x = (b3*(omega/k_x)*(
              (1.+eta)*kappa - 1j*alpha*(1.+3.*eta) + kappa/(1./(gamma-1) - nu*root)
              )
            - b1*(omega/k_x)*(
              (1.+4.*eta)*root - eta - beta - 1. + (root-1.)/(1./(gamma-1.) - nu*root)
              + 1j*sigma*beta*(1.-b3**2)
              )
            )
      return A_x


    def A_z(self,kappa,root,alpha,beta,eta,nu,sigma,b1,b3,gamma,omega,k_x):
      """
      [Francis, 1973] (Equation A20)
      """
      A_z = (b1*(omega/k_x)*(
              (1.+eta)*kappa + 2j*eta*alpha + (kappa-1j*alpha)/(1./(gamma-1.)-nu*root)
              )
            - b3*(omega/k_x)*(
              1. + eta - beta + 3.*eta*root + 1/(1./(gamma-1.)-nu*root) + 1j*sigma*beta*(1.-b1**2)
              )
            )
      return A_z

    def A_T(self,A_x,A_z,T_0,kappa,root,nu,gamma,omega,k_x):
      """
      [Francis, 1973] (Equation A21)
      """
      A_T = T_0*k_x/omega * ((A_x + kappa*A_z)/((1./(gamma-1.))-nu*root))
      return A_T

    def A_p(self,A_x,A_z,A_T,T_0,p_0,kappa,root,alpha,nu,gamma,omega,k_x):
      """
      [Francis, 1973] (Equation A22)
      """
      A_p = p_0*k_x/omega * (A_x+A_z*(kappa-1j*alpha)) + p_0 * (A_T/T_0)
      return A_p

    def A_chi(self,A_p,A_z,p_0,omega,H,mu,k_x,k_z):
      """
      Continuty of pressure tensor.
      [Francis, 1973] (Equation A16)
      """
      chi = A_p - (p_0*A_z)/(1j*omega*H) + (4./3.)*mu*1j*k_z*A_z - (2./3.)*mu*1j*k_x*A_z
      return chi

    def xi(self,x,z,t,omega,k_x,H):
      """
      Part of complex exponential not involving k_z.
      [Francis, 1973] (Equation A18)
      """
      xi = np.exp(1j*omega*t - 1j*k_x*x + z/(2.*H))
      return xi

    def ez(self,k_z,z):
      """
      Complex exponential including k_z.
      [Francis, 1973] (Equation A18)
      """
      ez = np.exp(-1j*k_z*z)
      return ez

    def a11_dn(self,A_z_dn,A_chi_dn,A_z_up,A_chi_up,e_dzm_dn,e_dzm_up):
      """
      Element for transition matrix.
      Similar to Friedman [1966], Equation 26, but solved 
      for the Francis [1973] setup.
      """
      a11_dn = ((A_chi_up*A_z_dn)/(A_z_dn*A_chi_up-A_z_up*A_chi_dn)) * e_dzm_dn
      return a11_dn

    def a11_up(self,A_z_dn,A_chi_dn,A_z_up,A_chi_up,e_dzm_dn,e_dzm_up):
      """
      Element for transition matrix.
      Similar to Friedman [1966], Equation 26, but solved 
      for the Francis [1973] setup.
      """
      a11_up = ((A_chi_dn*A_z_up)/(A_chi_dn*A_z_up+A_chi_up*A_z_dn)) * e_dzm_up
      return a11_up

    def a12_dn(self,A_z_dn,A_chi_dn,A_z_up,A_chi_up,e_dzm_dn,e_dzm_up):
      """
      Element for transition matrix.
      Similar to Friedman [1966], Equation 26, but solved 
      for the Francis [1973] setup.
      """
      a12_dn = (( A_z_up*A_z_dn)/(A_z_up*A_chi_dn-A_z_dn*A_chi_up)) * e_dzm_dn
      return a12_dn

    def a12_up(self,A_z_dn,A_chi_dn,A_z_up,A_chi_up,e_dzm_dn,e_dzm_up):
      """
      Element for transition matrix.
      Similar to Friedman [1966], Equation 26, but solved 
      for the Francis [1973] setup.
      """
      a12_up = ((-A_z_dn*A_z_up)/(A_z_dn*A_chi_up+A_z_up*A_chi_dn)) * e_dzm_up
      return a12_up

    def a21_dn(self,A_z_dn,A_chi_dn,A_z_up,A_chi_up,e_dzm_dn,e_dzm_up):
      """
      Element for transition matrix.
      Similar to Friedman [1966], Equation 26, but solved 
      for the Francis [1973] setup.
      """
      a21_dn = ((A_chi_up*A_chi_dn)/(A_z_dn*A_chi_up-A_z_up*A_chi_dn)) * e_dzm_dn
      return a21_dn

    def a21_up(self,A_z_dn,A_chi_dn,A_z_up,A_chi_up,e_dzm_dn,e_dzm_up):
      """
      Element for transition matrix.
      Similar to Friedman [1966], Equation 26, but solved 
      for the Francis [1973] setup.
      """
      a21_up = ((A_chi_dn*A_chi_up)/(A_chi_dn*A_z_up+A_chi_up*A_z_dn)) * e_dzm_up 
      return a21_up

    def a22_dn(self,A_z_dn,A_chi_dn,A_z_up,A_chi_up,e_dzm_dn,e_dzm_up):
      """
      Element for transition matrix.
      Similar to Friedman [1966], Equation 26, but solved 
      for the Francis [1973] setup.
      """
      a22_dn = (( A_z_up*A_chi_dn)/(A_z_up*A_chi_dn-A_z_dn*A_chi_up)) * e_dzm_dn
      return a22_dn

    def a22_up(self,A_z_dn,A_chi_dn,A_z_up,A_chi_up,e_dzm_dn,e_dzm_up):
      """
      Element for transition matrix.
      Similar to Friedman [1966], Equation 26, but solved 
      for the Francis [1973] setup.
      """
      a22_up = ((-A_z_dn*A_chi_up)/(A_chi_dn*A_z_up+A_chi_up*A_z_dn)) * e_dzm_up 
      return a22_up

class erw_functions(object):
  def c(self,gamma,R_gas,temp,M):
    """Speed of sound c [m/s]:
    gamma:  ratio of specific heats
    R_gas:  Ideal Gas Constant [J / (mol K)]
    temp:   Temperature [K]
    M:      Average Molecular Mass [kg/mol]
    [Francis, 1974] Equation (2)
    """
    c = np.sqrt((gamma * R_gas * temp) / M)
    return c

  def H(self,gamma,g,c):
    """Scale height of the neutral atmosphere [m]:
    gamma:  ratio of specific heats
    g:      gravity [m s^{-2}]
    c:      speed of sound [m/s]
    """
    H = c**2/(gamma*g)
    return H

  def omega_a(self,gamma,g,c):
    """Acoustic cutoff frequency omega_a [radians]:
    gamma:  ratio of specific heats
    g:      gravity [m s^{-2}]
    c:      speed of sound [m/s]
    [Francis, 1974] Equation (4)
    """
    omega_a = (gamma * g) / (2*c)
    return omega_a

  def omega_b(self,gamma,g,c):
    """Brunt-Väisälä frequency omega_b [radians]:
    gamma:  ratio of specific heats
    g:      gravity [m s^{-2}]
    c:      speed of sound [m/s]
    [Francis, 1974] Equation (3)
    """
    omega_b = np.sqrt( ( (gamma-1)*(g**2) ) / c**2 )
    return omega_b

  def k_z(self,k_x,omega,omega_a,omega_b,c):
    """Complex vertical wavenumber k_z [radians m^{-1}]:
    k_x:      Horizontal wavenumber [radians m^{-1}]
    omega:    Gravity Wave Frequency [radians]
    omega_a:  Acoustic cutoff frequency [radians]
    omega_b:  Brunt-Väisälä frequency [radians]
    gamma:    ratio of specific heats
    c:        speed of sound [m/s]
    [Francis, 1974] Equation (16)
    """
    
    k_z_r =    np.lib.scimath.sqrt((omega_b**2-omega**2)/(omega**2)*k_x**2 - (omega_a**2-omega**2)/(c**2))
    k_z_i = 1j*np.lib.scimath.sqrt((omega_a**2-omega**2)/(c**2) - (omega_b**2-omega**2)/(omega**2)*k_x**2)
    k_z   = np.zeros_like(k_z_i,dtype=np.complex128)

    boundary = (omega**2/c**2) * ((omega_a**2-omega**2)/(omega_b**2-omega**2))
    inx = np.where(k_x**2 >= boundary)
    if np.size(inx) > 0: k_z[inx] = k_z_r[inx]
    inx = np.where(k_x**2 < boundary)
    if np.size(inx) > 0: k_z[inx] = k_z_i[inx]
    return k_z
      
  def A(self,omega,omega_a,gamma,g):
    """Coefficient A:
    omega:    Gravity Wave Frequency [radians]
    omega_a:  Acoustic cutoff frequency [radians]
    gamma:    ratio of specific heats
    g:        gravity [m s^{-2}]
    [Francis, 1974] Equation (20)
    """
    A = (2*omega_a**2 - gamma*omega**2)/(gamma*g)
    return A

  def B(self,gamma,g,c):
    """Coefficient B:
    gamma:    ratio of specific heats
    g:        gravity [m s^{-2}]
    c:        speed of sound [m/s]
    [Francis, 1974] Equation (21)
    """
    B = (g/c**2)*(1.-(gamma/2.))
    return B

  def C(self,omega,omega_b,gamma,c):
    """Coefficient A:
    omega:    Gravity Wave Frequency [radians]
    omega_b:  Brunt-Väisälä frequency [radians]
    gamma:    ratio of specific heats
    c:      speed of sound [m/s]
    [Francis, 1974] Equation (22)
    """
    C = (c**2/gamma)*(omega/(omega_b**2-omega**2))
    return C

  def D(self,omega,omega_b,gamma,g):
    """Coefficient D:
    omega:    Gravity Wave Frequency [radians]
    omega_b:  Brunt-Väisälä frequency [radians]
    gamma:    ratio of specific heats
    g:        gravity [m s^{-2}]
    [Francis, 1974] Equation (23)
    """
    D = (omega*g)/(omega_b**2-omega**2)
    return D

  def t_L(self,omega_a1,omega_b1,c1,x):
    """Earliest time wave can arrive at field point [sec]:
    omega_a1: Acoustic cutoff frequency for lower atmosphere [radians]
    omega_b1: Brunt-Väisälä frequency for lower atmosphere [radians]
    c1:       Speed of sound in the lower atmosphere [m/s]
    x:        Horizontal distance from source region [m]
    [Francis, 1974] Equation (44)
    """
    t_L = (omega_a1/(c1*omega_b1)) * x
    return t_L

  def omega_c1(self,z_0,z_s,x,omega_b1,dz,H1,waveType='reflected'):
    """Scaled Brunt-Väisälä frequency for lower atmosphere omega_c1 [radians]:
    z_0:      Altitude of sound speed discontinuity [m]
    z_s:      Altitude of source region [m]
    x:        Horizontal distance from source region [m]
    omega_b1: Brunt-Väisälä frequency for lower atmosphere [radians]
    dz:       Vertical half-width of source region [m]
    H1:       Scale height of the lower atmosphere [m]
    [Francis, 1974] Equation (68)
    """
    if waveType == 'direct':
      wvt = -1
    else:
      wvt = 1

    omega_c1 = np.array(omega_b1*(z_0 + wvt*z_s + wvt*(dz**2/(4.*H1))),dtype=np.float64)/x
    return omega_c1

  def omega_c2(self,z,z_0,x,omega_b2):
    """Scaled Brunt-Väisälä frequency for thermosphere omega_c2 [radians]:
    z_0:      Altitude of sound speed discontinuity [m]
    z:        Observation Altitude [m]
    x:        Horizontal distance from source region [m]
    [Francis, 1974] Equation (46)
    """
    omega_c2 = np.array(omega_b2*(z-z_0),dtype=np.float64)/x
    return omega_c2

  def omega_bar(self,t,t_L,omega_c1,omega_c2):
    """Stationary phase approximation of frequency omega_bar:
    omega:    Gravity Wave Frequency [radians]
    omega_c1: Scaled Brunt-Väisälä frequency for lower atmosphere [radians]
    omega_c2: Scaled Brunt-Väisälä frequency for thermosphere [radians]
    t_L:      Earliest time low frequency gravity waves can reach the field point [s]
    [Francis, 1974] Equation (48)
    """
    omega_bar = omega_c2 + (omega_c1*t)/np.lib.scimath.sqrt(t**2 - t_L**2)
    return omega_bar

  def k_x_bar(self,x,t_L,omega_bar,omega_c1,omega_c2):
    """Stationary phase approximation of horizontal wave number k_x [radians/m]:
    omega_bar:Stationary phase approximation of gravity wave frequency [radians/sec]
    omega_c1: Scaled Brunt-Väisälä frequency for lower atmosphere [radians]
    omega_c2: Scaled Brunt-Väisälä frequency for thermosphere [radians]
    t_L:      Earliest time low frequency gravity waves can reach the field point [s]
    [Francis, 1974] Equation (50)
    """
    k_x_bar = ( (omega_bar*t_L * (omega_bar - omega_c2)) 
              / (x*np.lib.scimath.sqrt( (omega_bar-omega_c2)**2 - omega_c1**2 ))
              )
    return k_x_bar

  def R_0(self,k_z1,B1):
    """Ground reflection coefficient R_0:
    [Francis, 1974] Equation (25)
    """
    R_0 = (1j*k_z1 - B1)/(1j*k_z1 + B1)
    return R_0

  def R(self,k_z1,k_z2,A1,A2,B1,B2,C1,C2,D1,D2):
    """Thermospheric boundary reflection coefficient R:
    [Francis, 1974] Equation (26)
    """
    num = C2*D1*(1j*k_z2+B2)*( 1j*k_z1+A1) - C1*D2*( 1j*k_z1+B1)*(1j*k_z2+A2)
    den = C2*D1*(1j*k_z2+B2)*(-1j*k_z1+A1) - C1*D2*(-1j*k_z1+B1)*(1j*k_z2+A2)
    R   = -(num / den)
    return R

  def T(self,k_z1,k_z2,A1,A2,B1,B2,C1,C2,D1,D2):
    """Thermospheric boundary transmission coefficient T:
    [Francis, 1974] Equation (27)
    """
    num = 2*C1*D1*1j*k_z1 * (A1-B1)
    den = C2*D1*(1j*k_z2+B2)*(-1j*k_z1+A1) - C1*D2*(-1j*k_z1+B1)*(1j*k_z2+A2)
    T   = num / den
    return T

class atmos(object):
  def __init__(self,altitude,glat,glon,date):
    #MSIS help.
    #####The fortran subroutine needed is gtd7:
    #* **INPUTS**:
    #  * **IYD** - year and day as YYDDD (day of year from 1 to 365 (or 366)) (Year ignored in current model)
    #  * **SEC** - UT (SEC)
    #  * **ALT** - altitude (KM)
    #  * **GLAT** - geodetic latitude (DEG)
    #  * **GLONG** - geodetic longitude (DEG)
    #  * **STL** - local aparent solar time (HRS; see Note below)
    #  * **F107A** - 81 day average of F10.7 flux (centered on day DDD)
    #  * **F107** - daily F10.7 flux for previous day
    #  * **AP** - magnetic index (daily) OR when SW(9)=-1., array containing:
    #      * (1) daily AP
    #      * (2) 3 HR AP index FOR current time
    #      * (3) 3 HR AP index FOR 3 hrs before current time
    #      * (4) 3 HR AP index FOR 6 hrs before current time
    #      * (5) 3 HR AP index FOR 9 hrs before current time
    #      * (6) average of height 3 HR AP indices from 12 TO 33 HRS prior to current time
    #      * (7) average of height 3 HR AP indices from 36 TO 57 HRS prior to current time
    #  * **MASS** - mass number (only density for selected gass is calculated.  MASS 0 is temperature.  
    #    MASS 48 for ALL. MASS 17 is Anomalous O ONLY.)
    #* **OUTPUTS**:
    #  * **D(1)** - HE number density(CM-3)
    #  * **D(2)** - O number density(CM-3)
    #  * **D(3)** - N2 number density(CM-3)
    #  * **D(4)** - O2 number density(CM-3)
    #  * **D(5)** - AR number density(CM-3)                       
    #  * **D(6)** - total mass density(GM/CM3)
    #  * **D(7)** - H number density(CM-3)
    #  * **D(8)** - N number density(CM-3)
    #  * **D(9)** - Anomalous oxygen number density(CM-3)
    #  * **T(1)** - exospheric temperature
    #  * **T(2)** - temperature at ALT

    from models import msis
    solInput = msis.getF107Ap(date)
    msis.meters(True)   #Put into SI units.
    mass = 48           #Calculate all masses.
    self.altitude = altitude
    altitude = get_iterable(altitude)
    iyd = (date.year - date.year/100*100)*100 + date.timetuple().tm_yday
    sec = date.hour*24. + date.minute*60.
    stl = sec/3600. + glon/15.

    self.temp   = np.zeros(np.shape(altitude))
    self.dens   = np.zeros(np.shape(altitude))
    self.N2dens = np.zeros(np.shape(altitude))
    self.O2dens = np.zeros(np.shape(altitude))
    self.Odens  = np.zeros(np.shape(altitude))
    self.Ndens  = np.zeros(np.shape(altitude))
    self.Ardens = np.zeros(np.shape(altitude))
    self.Hdens  = np.zeros(np.shape(altitude))
    self.Hedens = np.zeros(np.shape(altitude))
    
    for ia,alt in enumerate(altitude):
        d,t = msis.gtd7(iyd, sec, alt, glat, glon, stl, solInput['f107a'], solInput['f107'], solInput['ap'], mass)
        self.temp[ia]   = t[1]
        self.dens[ia]   = d[5]
        self.N2dens[ia] = d[2]
        self.O2dens[ia] = d[3]
        self.Ndens[ia]  = d[7]
        self.Odens[ia]  = d[1]
        self.Hdens[ia]  = d[6]
        self.Hedens[ia] = d[0]
        self.Ardens[ia] = d[4]

    avogNr = 6.02e23
    self.numDens= self.N2dens + self.O2dens + self.Odens + self.Ndens + self.Ardens + self.Hdens + self.Hedens
    self.molDens  = self.numDens / avogNr
    self.pressure = self.molDens * R_gas * self.temp
    self.molMass  = self.dens / self.molDens

    self.N2molDens = self.N2dens / avogNr
    self.O2molDens = self.O2dens / avogNr
    self.NmolDens  = self.Ndens  / avogNr
    self.OmolDens  = self.Odens  / avogNr
    self.HmolDens  = self.Hdens  / avogNr
    self.HemolDens = self.Hedens / avogNr
    self.ArmolDens = self.Ardens / avogNr

    amu = 1.660538921e-27 #kg
    self.N2massDens = self.N2dens * 2. * 14.01 * amu
    self.O2massDens = self.O2dens * 2. * 16.00 * amu
    self.NmassDens  = self.Ndens  * 1. * 14.01 * amu
    self.OmassDens  = self.Odens  * 1. * 16.00 * amu
    self.HmassDens  = self.Hdens  * 1. * 1.008 * amu
    self.HemassDens = self.Hedens * 1. * 4.003 * amu
    self.ArmassDens = self.Ardens * 1. * 39.95 * amu

    #Use the Sutherland formula to compute viscosity.
    #Sutherland formula constants.  See the following pages for references:
    #http://mac6.ma.psu.edu/stirling/simulations/DHT/ViscosityTemperatureSutherland.html [He]
    #Tuples have the form (mu_0,T_0,C_suth), where:
    #  mu_0:   Reference viscosity [kg/(m*sec)] at temperature T_0
    #  T_0:    Reference temperature [K]
    #  C_suth: Sutherland temperature [K]
    suth = {}
    suth['He'] = (18.85e-6, 273.00,  79.4)
    suth['N2'] = (17.81e-6, 300.55, 111.0)
    suth['O2'] = (20.18e-6, 292.25, 127.0)
    suth['Ar'] = (21.25e-6, 273.00, 144.0)

    #Specific Heat, constant pressure [J/(mol*K)]
    C_p = {}
    C_p['He'] = 20.7862
    C_p['N2'] = 29.12
    C_p['O2'] = 29.38
    C_p['Ar'] = 20.7862

    # Viscosity [kg/(m*sec)]
    mu_He = self.sutherland(self.temp,suth['He'])
    mu_N2 = self.sutherland(self.temp,suth['N2'])
    mu_O2 = self.sutherland(self.temp,suth['O2'])
    mu_Ar = self.sutherland(self.temp,suth['Ar'])

    # Viscosity Weighted average
    num = mu_He*self.Hedens + mu_N2*self.N2dens + mu_O2*self.O2dens + mu_Ar*self.Ardens
    den = self.Hedens + self.N2dens + self.O2dens + self.Ardens
    self.mu = num/den

    # Kinematic Viscosity nu [m**2/sec]
    nu_He = mu_He / self.HemassDens
    nu_N2 = mu_N2 / self.N2massDens
    nu_O2 = mu_O2 / self.O2massDens
    nu_Ar = mu_Ar / self.ArmassDens
    
    # Kinematic Viscosity Weighted Average
    num = nu_He*self.Hedens + nu_N2*self.N2dens + nu_O2*self.O2dens + nu_Ar*self.Ardens
    den = self.Hedens + self.N2dens + self.O2dens + self.Ardens
    self.nu = num/den

    #Thermal Diffusivity kappa [m**2/sec]
    #Assume a constant Prandtl Number Pr = 0.7 [Vadas and Fritts, 2004; Kundu, 1990]
    Pr = 0.7
    kappa_He = nu_He / Pr
    kappa_N2 = nu_N2 / Pr
    kappa_O2 = nu_O2 / Pr
    kappa_Ar = nu_Ar / Pr
    
    # Thermal Diffusivity Weighted Average
    num = kappa_He*self.Hedens + kappa_N2*self.N2dens + kappa_O2*self.O2dens + kappa_Ar*self.Ardens
    den = self.Hedens + self.N2dens + self.O2dens + self.Ardens
    self.kappa = num/den

    #Thermal Conductivity lambda [(kg m)/(s**3 K)]
    lambda_He = kappa_He * self.HemolDens * C_p['He']
    lambda_N2 = kappa_N2 * self.N2molDens * C_p['N2'] 
    lambda_O2 = kappa_O2 * self.O2molDens * C_p['O2']
    lambda_Ar = kappa_Ar * self.ArmolDens * C_p['Ar']

    # Thermal Diffusivity Weighted Average
    num = lambda_He*self.Hedens + lambda_N2*self.N2dens + lambda_O2*self.O2dens + lambda_Ar*self.Ardens
    den = self.Hedens + self.N2dens + self.O2dens + self.Ardens
    self.lambda_th = num/den

  def sutherland(self,temp,constants):
    mu_0 = constants[0]
    T_0  = constants[1]
    S    = constants[2]

    mu = mu_0 * (temp/T_0)**(3/2.) * (T_0 + S)/(temp + S)
    return mu

  def plotViscosity(self):
    mp.figure(figsize=(16,8))
    #rcParams.update({'font.size': 12})

    rows  = 1
    cols  = 4
    np    = 0

    np = np+1
    mp.subplot(rows,cols,np)
    mp.plot(self.mu,self.altitude)
    mp.gca().set_xscale('log')
#    mp.gca().set_yticklabels([])
    mp.xlabel(r'Average Viscosity $\overline{\mu}$ [kg/(m sec)]')
    mp.ylabel(r'Altitude [km]')
    mp.grid()

    np = np+1
    mp.subplot(rows,cols,np)
    mp.plot(10000*self.nu,self.altitude)
    mp.gca().set_xscale('log')
#    mp.gca().set_yticklabels([])
    mp.xlabel(r'Average Kinematic Viscosity $\nu$ [cm$^2$/sec]')
    mp.ylabel(r'Altitude [km]')
    mp.grid()

    np = np+1
    mp.subplot(rows,cols,np)
    mp.plot(10000*self.kappa,self.altitude)
    mp.gca().set_xscale('log')
#    mp.gca().set_yticklabels([])
    mp.xlabel(r'Average Thermal Diffusivity $\kappa$ [cm$^2$/sec]')
    mp.ylabel(r'Altitude [km]')
    mp.title(r'Assuming Prandtl Pr = 0.7')
    mp.grid()

    np = np+1
    mp.subplot(rows,cols,np)
    mp.plot(self.lambda_th,self.altitude)
    mp.gca().set_xscale('log')
#    mp.gca().set_yticklabels([])
#    mp.xlabel(r'Average Thermal Conductivity $\lambda$ \left[\frac{\mbox{kg m}}{\mbox{K s}^3}\right]$')
    mp.xlabel(r'Average Thermal Conductivity $\lambda$ [(kg m)/(K s^3)]')
    mp.ylabel(r'Altitude [km]')
    mp.grid()

    title = r'Currently only using O$_2$, N$_2$, He, and Ar'
    mp.suptitle(title)
    mp.tight_layout()
    mp.subplots_adjust(top=0.90)
  def plot(self):
#    mp.figure(figsize=(16,16))
    mp.figure(figsize=(12,12))
    #rcParams.update({'font.size': 12})

    mp.subplot(231)
    mp.plot(self.temp, self.altitude)
    mp.gca().set_xscale('log')
    mp.xlabel('Temp. [K]')
    mp.ylabel('Altitude [km]')

    mp.subplot(232)
    mp.plot(self.dens, self.altitude)
    mp.gca().set_xscale('log')
    mp.gca().set_yticklabels([])
    mp.xlabel(r'Mass dens. [kg/m$^3$]')

    mp.subplot(233)
    mp.plot(self.Odens, self.altitude, 'r-', 
            self.O2dens, self.altitude, 'r--',
            self.Ndens, self.altitude, 'g-',
            self.N2dens, self.altitude, 'g--',
            self.Hdens, self.altitude, 'b-',
            self.Hedens, self.altitude, 'y-',
            self.Ardens, self.altitude, 'm-')
    mp.gca().set_xscale('log')
    mp.gca().set_yticklabels([])
    mp.xlabel(r'Density [m$^{-3}$]')
    leg = mp.legend(  (r'O', 
                    r'O$_2$', 
                    r'N',
                    r'N$_2$',
                    r'H',
                    r'He',
                    r'Ar',),
               'upper right')

    mp.subplot(234)
    mp.plot(self.numDens, self.altitude)
    mp.gca().set_xscale('log')
    mp.xlabel(r'Density [m$^{-3}$]')
    mp.ylabel('Altitude [km]')

    mp.subplot(235)
    mp.plot(self.molDens, self.altitude)
    mp.gca().set_xscale('log')
    mp.xlabel(r'Molar Density [mol/m$^{3}$]')
    mp.ylabel('Altitude [km]')

    mp.subplot(236)
    mp.plot(self.pressure, self.altitude)
    mp.gca().set_xscale('log')
    mp.xlabel(r'Pressure [Pa]')
    mp.ylabel('Altitude [km]')

    mp.tight_layout()


class igrf(object):
  def __init__(self,z_s,glat,glon,date):
# Edits to switch IGRF to subroutine 
#C   INPUTS: 
#C       - ITYPE: 
#C           - 1 - geodetic (shape of Earth is approximated by a spheroid) 
#C           - 2 - geocentric (shape of Earth is approximated by a sphere) 
#C       - DATE: date in years A.D. (ignored if IOPT=2) 
#C       - ALT: altitude or radial distance in km (depending on ITYPE) 
#C       - XLTI,XLTF,XLTD: latitude (initial, final, increment) in decimal degrees 
#C       - XLNI,XLNF,XLND: longitude (initial, final, increment) in decimal degrees 
#C       - IFL: value for MF/SV flag: 
#C           - 0 for main field (MF) 
#C           - 1 for secular variation (SV) 
#C           - 2 for both 
#C   OUTPUTS: 
#C       - aLat is the latitude of each point 
#C       - aLon is the longitude of each point 
#C       - D is declination in degrees (+ve east) 
#C       - I is inclination in degrees (+ve down) 
#C       - H is horizontal intensity in nT 
#C       - X is north component in nT 
#C       - Y is east component in nT 
#C       - Z is vertical component in nT (+ve down) 
#C       - F is total intensity in nT
    # Don't forget... IGRF wants inputs in km!!
    #Go get some magnetic field data from IGRF.
    from models import igrf
    itype             = 1 # Geodetic coordinates
    xlti, xltf, xltd  = glat,glat+1.,1. # latitude start, stop, step
    xlni, xlnf, xlnd  = glon,glon+1.,1. # longitude start, stop, step
    ifl               = 0 # Main field
    # Call fortran subroutine
    z_s = get_iterable(z_s)
    self.lat = np.zeros(np.shape(z_s),dtype=np.float)
    self.lon = np.zeros(np.shape(z_s),dtype=np.float)
    self.dec = np.zeros(np.shape(z_s),dtype=np.float)
    self.inc = np.zeros(np.shape(z_s),dtype=np.float)
    self.h   = np.zeros(np.shape(z_s),dtype=np.float)
    self.x   = np.zeros(np.shape(z_s),dtype=np.float)
    self.y   = np.zeros(np.shape(z_s),dtype=np.float)
    self.z   = np.zeros(np.shape(z_s),dtype=np.float)
    self.B   = np.zeros(np.shape(z_s),dtype=np.float)
#    self.B   = np.zeros((np.size(z_s),4),dtype=np.float)
    self.zz  = np.zeros(np.shape(z_s),dtype=np.float)

    inx = 0
    for zz in z_s:
      lat,lon,dec,inc,h,x,y,z,B = igrf.igrf11(itype,date.year,zz,ifl,xlti,xltf,xltd,xlni,xlnf,xlnd)

      self.lat[inx] = lat[0]
      self.lon[inx] = lon[0]
      self.dec[inx] = dec[0]
      self.inc[inx] = inc[0]
      self.h[inx] = h[0]
      self.x[inx] = x[0]
      self.y[inx] = y[0]
      self.z[inx] = z[0]
      self.B[inx] = B[0]
      self.zz[inx] = zz
      inx = inx + 1

class multilayer(object):
  def __init__(self,omega,k_x,mu,lambda_th,T_0,p_0,sigma_p,b1,b3,B,rho_0,H,g,x,z,t):
    """
    omega:      Angular wave frequency [rad/s]
    k_x:        Horizontal wave number [rad/m]
    mu:         Coefficient of viscocity [kg/(m*sec)]
    lambda_th:  Coefficient of thermal conductivty [(kg*m)/(K*sec**3)]
    T_0:        Ambient temperature [K]
    p_0:        Ambienty pressure [Pa = kg/(m*sec**2)
    sigma_p:    Pedersen Conductivity [Si/m]
    b1:         I need to find out what this parameter is; it seems to be related to ion drag.
    b3:         I need to find out what this parameter is; it seems to be related to ion drag.
    B:          Magnetic Field [T]
    rho_0:      Mass density [kg/m**3]
    H:          Scale height [m]
    g:          Gravitational acceleration [m/(s**2)]
    """
    z     = np.array(z)

    ns    = ns_functions()
    alpha = ns.alpha(k_x,H)
    beta  = ns.beta(omega,g,k_x,H)
    eta   = ns.eta(omega,mu,p_0)
    nu    = ns.nu(lambda_th,T_0,k_x,omega,p_0)
    sigma = ns.sigma(sigma_p,B,rho_0,omega)

    C3    = ns.C3(eta,nu)
    C2    = ns.C2(beta,eta,nu,sigma,b1,b3,gamma)
    C1    = ns.C1(alpha,beta,eta,nu,sigma,b1,b3,gamma)
    C0    = ns.C0(alpha,beta,eta,sigma,b1,b3,gamma)


    C0_inx    = 0
    C1_inx    = 1
    C2_inx    = 2
    C3_inx    = 3
    alpha_inx = 4
    k_x_inx   = 5
    H_inx     = 6
    k_z_dn_inx    = 7
    k_z_up_inx    = 8
    kappa_dn_inx  = 9
    kappa_up_inx  = 10
    nGrowth_inx   = 11

    it = np.nditer([C0,C1,C2,C3,alpha,k_x,H,None,None,None,None,None])
    nn = -1
    size = np.size(C3)
    while not it.finished:
      nn = nn+1
      coefs = [it[C3_inx],it[C2_inx],it[C1_inx],it[C0_inx]]
      
      if not np.all(np.isfinite(coefs)):
#        print 'NaN',nn,'/',size
        it[k_z_dn_inx] = np.nan
        it[k_z_up_inx] = np.nan
        it[kappa_dn_inx] = np.nan
        it[kappa_up_inx] = np.nan
        it.iternext()
        continue

      roots = np.roots(coefs)

      D2    = 1
      D1    = -1j*it[alpha_inx]

      kappa_list  = []
      k_z_list    = []
      for root in roots:
        D0        = 1-root
        kappa_tmp = np.roots([D2,D1,D0])
        kappa_list.append(kappa_tmp)
        kz_tmp    = it[k_x_inx]*kappa_tmp - 1j/(2*it[H_inx])
        k_z_list.append(kz_tmp)

      #Pick out which k_z to use...
      #The dissapative waves (heat conduction and viscosity) are going to
      #be strongly damped (Large imaginary part that has the opposite sign
      #of the real part.)
      #The acoustic-gravity wave is going to grow (same sign real and imaginary part).
      #According to Francis [1973] pp 2296-2297, the dissapative waves
      #can be disregarded.

      #To try and automatically pick out the correct k_z.  For now, I'm just 
      #going to say that the k_z pair in which both k_z's show growth is the
      #correct one.  If there are none or more than one, drop to the debugger.
      #This will probably need to be adjusted later.

      growth = np.zeros(3)
      kk = 0
      for k_z in k_z_list:
        sign        = np.sign(np.real(k_z) * np.imag(k_z))
        growth[kk]  = sign[0] and sign[1]
        kk = kk + 1

      inx = np.where(growth == 1)
      nGrow   = np.size(inx)
      it[nGrowth_inx] = nGrow
      if nGrow != 1:
#        print 'I\'m not sure which k_z value to use for the GW... Help!!'
#        print k_z_list
        it[k_z_dn_inx]    = 0
        it[k_z_up_inx]    = 0
        it[kappa_dn_inx]  = 0
        it[kappa_up_inx]  = 0
      else:
        root    = roots[inx[0][0]]
        k_z     = np.sort(k_z_list[inx[0][0]])
        it[k_z_dn_inx] = k_z[0] #k_z_dn
        it[k_z_up_inx] = k_z[1] #k_z_up
        it[kappa_dn_inx] = (k_z[0] + 1j/(2.*it[H_inx]))/it[k_x_inx] #kappa_dn
        it[kappa_up_inx] = (k_z[1] + 1j/(2.*it[H_inx]))/it[k_x_inx] #kappa_up
      
#      print k_z,nn,'/',size
      it.iternext()

    k_z_dn    = it.operands[k_z_dn_inx]
    k_z_up    = it.operands[k_z_up_inx]
    kappa_dn  = it.operands[kappa_dn_inx]
    kappa_up  = it.operands[kappa_up_inx]
    nGrowth   = (it.operands[nGrowth_inx]).astype(np.int)

    #Compute the polarization constants...
    A_x_dn    = ns.A_x(kappa_dn,root,alpha,beta,eta,nu,sigma,b1,b3,gamma,omega,k_x)
    A_z_dn    = ns.A_z(kappa_dn,root,alpha,beta,eta,nu,sigma,b1,b3,gamma,omega,k_x)
    A_T_dn    = ns.A_T(A_x_dn,A_z_dn,T_0,kappa_dn,root,nu,gamma,omega,k_x)
    A_p_dn    = ns.A_p(A_x_dn,A_z_dn,A_T_dn,T_0,p_0,kappa_dn,root,alpha,nu,gamma,omega,k_x)
    A_chi_dn  = ns.A_chi(A_p_dn,A_z_dn,p_0,omega,H,mu,k_x,k_z_dn)

    A_x_up    = ns.A_x(kappa_up,root,alpha,beta,eta,nu,sigma,b1,b3,gamma,omega,k_x)
    A_z_up    = ns.A_z(kappa_up,root,alpha,beta,eta,nu,sigma,b1,b3,gamma,omega,k_x)
    A_T_up    = ns.A_T(A_x_up,A_z_up,T_0,kappa_up,root,nu,gamma,omega,k_x)
    A_p_up    = ns.A_p(A_x_up,A_z_up,A_T_up,T_0,p_0,kappa_up,root,alpha,nu,gamma,omega,k_x)
    A_chi_up  = ns.A_chi(A_p_up,A_z_up,p_0,omega,H,mu,k_x,k_z_up)

    dzm         = z - np.roll(z,1,1)
    dzm[:,0,:]  = np.nan

    e_dzm_dn = ns.ez(k_z_dn,dzm)
    e_dzm_up = ns.ez(k_z_up,dzm)

    #Transition matrix coefficients...
    a11_dn = ns.a11_dn(A_z_dn,A_chi_dn,A_z_up,A_chi_up,e_dzm_dn,e_dzm_up)
    a12_dn = ns.a12_dn(A_z_dn,A_chi_dn,A_z_up,A_chi_up,e_dzm_dn,e_dzm_up)
    a21_dn = ns.a21_dn(A_z_dn,A_chi_dn,A_z_up,A_chi_up,e_dzm_dn,e_dzm_up)
    a22_dn = ns.a22_dn(A_z_dn,A_chi_dn,A_z_up,A_chi_up,e_dzm_dn,e_dzm_up)

    a11_up = ns.a11_up(A_z_dn,A_chi_dn,A_z_up,A_chi_up,e_dzm_dn,e_dzm_up)
    a12_up = ns.a12_up(A_z_dn,A_chi_dn,A_z_up,A_chi_up,e_dzm_dn,e_dzm_up)
    a21_up = ns.a21_up(A_z_dn,A_chi_dn,A_z_up,A_chi_up,e_dzm_dn,e_dzm_up)
    a22_up = ns.a22_up(A_z_dn,A_chi_dn,A_z_up,A_chi_up,e_dzm_dn,e_dzm_up)
    import ipdb; ipdb.set_trace()

    shape     = np.shape(z)
    nx,nz,nt  = shape
    uz_pr_up  = np.zeros(shape,dtype=np.complex)
    uz_pr_dn  = np.zeros(shape,dtype=np.complex)
    chi_pr_up = np.zeros(shape,dtype=np.complex)
    chi_pr_dn = np.zeros(shape,dtype=np.complex)

    for xx in range(nx):
      for tt in range(nt):
        chi_pr_dn[xx,0,tt] = a22_dn[xx,0,tt]*chi_pr_dn[xx,m-1,t]
        chi_pr_up[xx,m,tt] = a21_up[xx,m,tt]*uz_pr_up[xx,m-1,tt] + a22_up[xx,m,tt]*chi_pr_up[xx,m-1,t]
      tt = tt+1
    xx = xx+1

    for xx in range(nx):
      for tt in range(nt):
        for m in range(nz-1)+1:
          uz_pr_dn[xx,m,tt] = a11_dn[xx,m,tt]*uz_pr_dn[xx,m-1,tt] + a12_dn[xx,m,tt]*chi_pr_dn[xx,m-1,t]
          uz_pr_up[xx,m,tt] = a11_up[xx,m,tt]*uz_pr_up[xx,m-1,tt] + a12_up[xx,m,tt]*chi_pr_up[xx,m-1,t]
          
          chi_pr_dn[xx,m,tt] = a21_dn[xx,m,tt]*uz_pr_dn[xx,m-1,tt] + a22_dn[xx,m,tt]*chi_pr_dn[xx,m-1,t]
          chi_pr_up[xx,m,tt] = a21_up[xx,m,tt]*uz_pr_up[xx,m-1,tt] + a22_up[xx,m,tt]*chi_pr_up[xx,m-1,t]
        tt = tt+1
      xx = xx+1


    #Basic Sinusoids...
    e_dn    = np.exp(1j*omega*tGrid - 1j*k_x*xGrid - 1j*k_z_dn*zGrid + zGrid/(2.*H))
    e_up    = np.exp(1j*omega*tGrid - 1j*k_x*xGrid - 1j*k_z_up*zGrid + zGrid/(2.*H))

    #Arbitary coefficients
    CF_dn   = 1.
    CF_up   = 1.

    p_pr_dn   = CF_dn * A_p_dn * e_dn
    T_pr_dn   = CF_dn * A_T_dn * e_dn
    ux_pr_dn  = CF_dn * A_x_dn * e_dn
    uz_pr_dn  = CF_dn * A_z_dn * e_dn

    p_pr_up   = CF_up * A_p_up * e_up
    T_pr_up   = CF_up * A_T_up * e_up
    ux_pr_up  = CF_up * A_x_up * e_up
    uz_pr_up  = CF_up * A_z_up * e_up

    p_pr_dn   = np.real(p_pr_dn)
    T_pr_dn   = np.real(T_pr_dn)
    ux_pr_dn  = np.real(ux_pr_dn)
    uz_pr_dn  = np.real(uz_pr_dn)

    p_pr_up   = np.real(p_pr_up)
    T_pr_up   = np.real(T_pr_up)
    ux_pr_up  = np.real(ux_pr_up)
    uz_pr_up  = np.real(uz_pr_up)

    self.x        = x
    self.z_z      = z_z
    self.t        = t
    self.k_z_up   = k_z_up
    self.k_z_dn   = k_z_dn

    self.p_pr_dn  = p_pr_dn 
    self.T_pr_dn  = T_pr_dn 
    self.ux_pr_dn = ux_pr_dn
    self.uz_pr_dn = uz_pr_dn

    self.p_pr_up  = p_pr_up 
    self.T_pr_up  = T_pr_up 
    self.ux_pr_up = ux_pr_up
    self.uz_pr_up = uz_pr_up

  def plotLayer(self,x_plot,t_plot,timeUnits='minutes',xaxis='range',lengthUnits='kilometers'):
    if timeUnits == 'minutes':
      t_plot = t_plot*60.
    elif timeUnits == 'hours':
      t_plot = t_plot*3600.

    if lengthUnits == 'kilometers':
      x_plot = x_plot * 1000.

    mp.figure(figsize=(20,11.5))
    #rcParams.update({'font.size': 12})
    x_inx = get_index(x_plot,self.x)
    t_inx = get_index(t_plot,self.t)
    self.x_inx = x_inx
    self.t_inx = t_inx

    z = self.z_z/1000.
    ylim = [np.min(z),np.max(z)]
    xLabel  = 'Altitude [km]'

    
    lm_up = (2.*np.pi)/np.real(self.k_z_up) / 1000.
    lm_dn = (2.*np.pi)/np.real(self.k_z_dn) / 1000.

    upperTitle = r'Upgoing Wave $\lambda_z=$'   + "{0:.0f}".format(lm_up) + ' km'
    lowerTitle = r'Downgoing Wave $\lambda_z=$' + "{0:.0f}".format(lm_dn) + ' km'

    nRows = 2
    nCols = 4
    pl    = 0

    pl = pl + 1
    mp.subplot(nRows,nCols,pl)
    mp.plot(self.p_pr_up[x_inx,:,t_inx],z)
#    mp.gca().set_xscale('log')
    mp.ylabel(xLabel)
    mp.xlabel(r"Pressure $p' [Pa]$")
    mp.title(upperTitle)
    mp.ylim(ylim)
    xfm = mp.gca().xaxis.get_major_formatter()
    xfm.set_powerlimits([ -3, 3])

    pl = pl + 1
    mp.subplot(nRows,nCols,pl)
    mp.plot(self.T_pr_up[x_inx,:,t_inx],z)
#    mp.gca().set_xscale('log')
    mp.ylabel(xLabel)
    mp.xlabel(r"Temperature $T'$ [K]")
    mp.title(upperTitle)
    mp.ylim(ylim)
    xfm = mp.gca().xaxis.get_major_formatter()
    xfm.set_powerlimits([ -3, 3])

    pl = pl + 1
    mp.subplot(nRows,nCols,pl)
    mp.plot(self.ux_pr_up[x_inx,:,t_inx],z)
#    mp.gca().set_xscale('log')
    mp.ylabel(xLabel)
    mp.xlabel(r"Horiz. Vel. $u_x'$ [m/s]")
    mp.title(upperTitle)
    mp.ylim(ylim)
    xfm = mp.gca().xaxis.get_major_formatter()
    xfm.set_powerlimits([ -3, 3])

    pl = pl + 1
    mp.subplot(nRows,nCols,pl)
    mp.plot(self.uz_pr_up[x_inx,:,t_inx],z)
#    mp.gca().set_xscale('log')
    mp.ylabel(xLabel)
    mp.xlabel(r"Vert. Vel. $u_x'$ [m/s]")
    mp.title(upperTitle)
    mp.ylim(ylim)
    xfm = mp.gca().xaxis.get_major_formatter()
    xfm.set_powerlimits([ -3, 3])

    pl = pl + 1
    mp.subplot(nRows,nCols,pl)
    mp.plot(self.p_pr_dn[x_inx,:,t_inx],z)
#    mp.gca().set_xscale('log')
    mp.ylabel(xLabel)
    mp.xlabel(r"Pressure $p' [Pa]$")
    mp.title(lowerTitle)
    mp.ylim(ylim)
    xfm = mp.gca().xaxis.get_major_formatter()
    xfm.set_powerlimits([ -3, 3])

    pl = pl + 1
    mp.subplot(nRows,nCols,pl)
    mp.plot(self.T_pr_dn[x_inx,:,t_inx],z)
#    mp.gca().set_xscale('log')
    mp.ylabel(xLabel)
    mp.xlabel(r"Temperature $T'$ [K]")
    mp.title(lowerTitle)
    mp.ylim(ylim)
    xfm = mp.gca().xaxis.get_major_formatter()
    xfm.set_powerlimits([ -3, 3])

    pl = pl + 1
    mp.subplot(nRows,nCols,pl)
    mp.plot(self.ux_pr_dn[x_inx,:,t_inx],z)
#    mp.gca().set_xscale('log')
    mp.ylabel(xLabel)
    mp.xlabel(r"Horiz. Vel. $u_x'$ [m/s]")
    mp.title(lowerTitle)
    mp.ylim(ylim)
    xfm = mp.gca().xaxis.get_major_formatter()
    xfm.set_powerlimits([ -3, 3])

    pl = pl + 1
    mp.subplot(nRows,nCols,pl)
    mp.plot(self.uz_pr_dn[x_inx,:,t_inx],z)
#    mp.gca().set_xscale('log')
    mp.ylabel(xLabel)
    mp.xlabel(r"Vert. Vel. $u_x'$ [m/s]")
    mp.title(lowerTitle)
    mp.ylim(ylim)
    mp.tight_layout()
    xfm = mp.gca().xaxis.get_major_formatter()
    xfm.set_powerlimits([ -3, 3])

def vline(xpos,string,color):
  ax = mp.gca()
  ax.axvline(xpos,ls='--',color=color,lw=2)
  ax.annotate(string,
      (1.00000001*xpos,0.01),
      xycoords=('data','axes fraction'),
      fontsize='small',
      weight='bold',
      rotation=90,
      color=color,
      verticalalignment='bottom',
      horizontalalignment='left')

def helpvar(name,var):
  print name + ' ' + str(np.shape(var)) + ' ' + str(np.size(var))

class gw(object):
  def __init__(self,x,z,t,z_0,c1,c2,z_s,I,dz,glat,glon,date,waveType='reflected',lengthUnits='kilometers'):
    #From here on out, do everything in meters...
    if lengthUnits=='kilometers':
      x   =   x * 1000.
      z   =   z * 1000.
      z_0 = z_0 * 1000.
      z_s = z_s * 1000.
      dz  =  dz * 1000.

    #Put everything into a mesh grid.
    self.x = x
    self.z = z
    self.t = t

    nx = np.size(x)
    nz = np.size(z)
    nt = np.size(t)

    self.grid = np.ones([nx,nz,nt])

    self.xGrid = self.grid * np.reshape(x,[nx,1,1])
    self.zGrid = self.grid * np.reshape(z,[1,nz,1])
    self.tGrid = self.grid * np.reshape(t,[1,1,nt])

    self.c1 = c1
    self.c2 = c2
    self.p_prime(self.xGrid,self.zGrid,self.tGrid,z_0,c1,c2,z_s,I,dz,glat,glon,date,waveType=waveType)
    self.vx_prime()

  def set_default_indices(self,x,z,t,timeUnits='minutes',lengthUnits='kilometers'):
    """Find the grid indices for a point in space and time
    and use these as the defaults for plotting.
    """
    if lengthUnits == 'kilometers':
      x = x * 1000.
      z = z * 1000.

    if timeUnits == 'minutes':
      t = t*60.
    elif timeUnits == 'hours':
      t = t*3600.

    x_inx = get_index(x,self.x)
    z_inx = get_index(z,self.z)
    t_inx = get_index(t,self.t)
    self.x_inx = x_inx
    self.z_inx = z_inx
    self.t_inx = t_inx
    return (x_inx,z_inx,t_inx)

  def p_prime(self,x,z,t,z_0,c1,c2,z_s,I,dz,glat,glon,date,waveType='reflected'):
    #Everything should be in meters by the time it gets to here.
    shape     = np.shape(x)
    nx,nz,nt  = np.shape(x)
    zShape    = [1,nz,1]


    #Get magnetic field model data.
    #Altitude needs to go in as [km].
    #Make sure we get the value in T, not nT.
    self.igrf_src = igrf(z_s/1000.,glat,glon,date)
    B_z_s     = (self.igrf_src.z) * 1e-9

    self.igrf = igrf(self.z/1000.,glat,glon,date)

    #Calculate pressure at the source altitude only.
    #Altitude needs to go in as [km].
    src_atm   = atmos(z_s/1000.,glat,glon,date)
    p0_z_s    = src_atm.pressure
    rho0_z_s  = src_atm.dens

    #Calculate the atmosphere for the entire grid.
    #Altitude needs to go in as [km].
    self.atm  = atmos(z[0,:,0]/1000.,glat,glon,date)
    p0_z      = self.grid * np.reshape(self.atm.pressure, zShape)
    temp_0    = self.grid * np.reshape(self.atm.temp    , zShape)
    rho_0     = self.grid * np.reshape(self.atm.dens    , zShape)

    fn = erw_functions()
    self.fn = fn
    
    self.c = fn.c(gamma,R_gas,self.atm.temp,self.atm.molMass)
    c        = self.grid * np.reshape(self.c           , zShape)

    H         = fn.H(gamma,g,c)
    H1        = fn.H(gamma,g,c1)
    omega_a1  = fn.omega_a(gamma,g,c1)
    omega_a2  = fn.omega_a(gamma,g,c2)
    omega_b1  = fn.omega_b(gamma,g,c1)
    omega_b2  = fn.omega_b(gamma,g,c2)

    t_L       = fn.t_L(omega_a1,omega_b1,c1,x)
    omega_c1  = fn.omega_c1(z_0,z_s,x,omega_b1,dz,H1,waveType=waveType)
    omega_c2  = fn.omega_c2(z,z_0,x,omega_b2)

    omega_bar = fn.omega_bar(t,t_L,omega_c1,omega_c2)
    k_x_bar   = fn.k_x_bar(x,t_L,omega_bar,omega_c1,omega_c2)
    k_z1 = fn.k_z(k_x_bar,omega_bar,omega_a1,omega_b1,c1)
    k_z2 = fn.k_z(k_x_bar,omega_bar,omega_a2,omega_b2,c2)

    A1  = fn.A(omega_bar,omega_a1,gamma,g)
    A2  = fn.A(omega_bar,omega_a2,gamma,g)
    B1  = fn.B(gamma,g,c1)
    B2  = fn.B(gamma,g,c2)
    C1  = fn.C(omega_bar,omega_b1,gamma,c1)
    C2  = fn.C(omega_bar,omega_b2,gamma,c2)
    D1  = fn.D(omega_bar,omega_b1,gamma,g)
    D2  = fn.D(omega_bar,omega_b2,gamma,g)
    T   = fn.T(k_z1,k_z2,A1,A2,B1,B2,C1,C2,D1,D2)
    R_0 = fn.R_0(k_z1,B1)
    R   = fn.R(k_z1,k_z2,A1,A2,B1,B2,C1,C2,D1,D2)

    if waveType == 'direct':
      TR = T
    else:
      TR = T*R_0
    phi = np.real(-1j*np.log(TR/np.abs(T)))

#    T = self.grid

#    poi = self.set_default_indices(50,200,1)
#    lambda_th = self.atm.lambda_th[poi[1]]
#    mu        = self.atm.mu[poi[1]]
#    sigma_p   = 0
#    b1        = (np.cos(self.igrf.inc * (np.pi/180.)))[poi[1]]
#    b3        = (np.sin(self.igrf.inc * (np.pi/180.)))[poi[1]]
#    B         = (self.igrf.B[poi[1]]) * 10**-9

    lambda_th = self.grid * np.reshape(self.atm.lambda_th, zShape)
    mu        = self.grid * np.reshape(self.atm.mu       , zShape)
    sigma_p   = 0
    B         = self.igrf.B * 10**-9
    b1        = (np.cos(self.igrf.inc * (np.pi/180.)))
    b3        = (np.sin(self.igrf.inc * (np.pi/180.)))
    B         = self.grid * np.reshape(B ,zShape)
    b1        = self.grid * np.reshape(b1,zShape)
    b3        = self.grid * np.reshape(b3,zShape)

    helpvar('omega_bar',omega_bar)
    helpvar('k_x_bar',k_x_bar)
    helpvar('mu',mu)
    helpvar('lambda_th',lambda_th)
    helpvar('temp_0',temp_0)
    helpvar('p0_z',p0_z)
    helpvar('sigma_p',sigma_p)
    helpvar('b1',b1)
    helpvar('b3',b3)
    helpvar('B',B)
    helpvar('rho_0',rho_0)
    helpvar('H',H)
    helpvar('g',g)

    poi = self.set_default_indices(600,200,4,timeUnits='hours')
    omega_bar_ml  = np.reshape(omega_bar[poi[0],:,poi[2]],zShape)
    k_x_bar_ml    = np.reshape(k_x_bar[poi[0],:,poi[2]],zShape)
    mu_ml         = np.reshape(mu[poi[0],:,poi[2]],zShape)
    lambda_th_ml  = np.reshape(lambda_th[poi[0],:,poi[2]],zShape)
    temp_0_ml     = np.reshape(temp_0[poi[0],:,poi[2]],zShape)
    p0_z_ml       = np.reshape(p0_z[poi[0],:,poi[2]],zShape)
    sigma_p_ml    = sigma_p
    b1_ml         = np.reshape(b1[poi[0],:,poi[2]],zShape)
    b3_ml         = np.reshape(b3[poi[0],:,poi[2]],zShape)
    B_ml          = np.reshape(B[poi[0],:,poi[2]],zShape)
    rho_0_ml      = np.reshape(rho_0[poi[0],:,poi[2]],zShape)
    H_ml          = np.reshape(H[poi[0],:,poi[2]],zShape)
    g_ml          = g
    x_ml          = np.reshape(x[poi[0],:,poi[2]],zShape)
    z_ml          = np.reshape(z[poi[0],:,poi[2]],zShape)
    t_ml          = np.reshape(t[poi[0],:,poi[2]],zShape)
    
    self.ml = multilayer(
        omega_bar_ml,
        k_x_bar_ml,
        mu_ml,
        lambda_th_ml,
        temp_0_ml,
        p0_z_ml,
        sigma_p_ml,
        b1_ml,
        b3_ml,
        B_ml,
        rho_0_ml,
        H_ml,
        g_ml,
        x_ml, z_ml, t_ml)

#    self.ml = multilayer(
#        omega_bar,
#        k_x_bar,
#        mu,
#        lambda_th,
#        temp_0,
#        p0_z,
#        sigma_p,
#        b1,
#        b3,
#        B,
#        rho_0,
#        H,
#        g,
#        x, z, t)
    
    #[Francis, 1974] Equation (67)
    #Here rho0_z_s is a mass density [kg/m^3]
    pp = ( np.abs(T)
         * ( (I*gamma*omega_b1*B_z_s*t)
           / (2.*np.pi*(c1**2)*rho0_z_s*x) )
         * np.exp( (dz/(4*H1))**2
           - ((omega_b1*np.sqrt(t**2 - t_L**2)*dz)/(2*x))**2
             )
         * ( (np.sin(omega_c1*np.sqrt(t**2-t_L**2) + omega_c2*t + phi))
           / (omega_c1*t + omega_c2*np.sqrt(t**2-t_L**2))
           )
         )
    self.pp         = pp

    self.ppA = np.abs(T)
    self.ppB = ( (I*gamma*omega_b1*B_z_s*t)
               / (2.*np.pi*(c1**2)*rho0_z_s*x) )
    self.ppC = np.exp( (dz/(4*H1))**2
               - ((omega_b1*np.sqrt(t**2 - t_L**2)*dz)/(2*x))**2
               )
    self.ppD = (1 / (omega_c1*t + omega_c2*np.sqrt(t**2-t_L**2)))

    self.ppE =  self.ppA * self.ppB * self.ppC * self.ppD

    self.ppF = ( (np.sin(omega_c1*np.sqrt(t**2-t_L**2) + omega_c2*t + phi))
               / (omega_c1*t + omega_c2*np.sqrt(t**2-t_L**2))
               )
    self.test7 = np.lib.scimath.sqrt((t**2-t_L**2))
    self.test8 = omega_c1*np.lib.scimath.sqrt((t**2-t_L**2))
    self.test9 = omega_c2*t + omega_c1*np.lib.scimath.sqrt((t**2-t_L**2)) + phi

    self.A1   = A1
    self.A2   = A2
    self.B1   = B1
    self.B2   = B2
    self.C1   = C1
    self.C2   = C2
    self.D1   = D1
    self.D2   = D2

    self.p0_z_s     = p0_z_s
    self.p0_z       = p0_z
    self.absT       = np.abs(T)
    self.I          = I
    self.gamma      = gamma
    self.B_z_s      = B_z_s
    self.rho0_z_s   = rho0_z_s

    self.omega_a1   = omega_a1
    self.omega_a2   = omega_a2
    self.omega_b1   = omega_b1
    self.omega_b2   = omega_b2
    self.omega_c1   = omega_c1
    self.omega_c2   = omega_c2
    self.t_L        = t_L
    self.omega_bar  = omega_bar
    self.k_x_bar    = k_x_bar
    self.k_z1       = k_z1
    self.k_z2       = k_z2
    self.T          = T
    self.phi        = phi

  def vx_prime(self):
    vp = ((self.c2**2)*self.k_x_bar)/(gamma*self.omega_bar)
    self.vpCoef = vp
    self.vp = vp * self.pp


  def plotRangeV_Prime(self,z_plot,t_plot,timeUnits='minutes'):
    t_plot = np.array(t_plot)
    if timeUnits == 'minutes':
      t_plot = t_plot*60.
    elif timeUnits == 'hours':
      t_plot = t_plot*3600.

    mp.figure(figsize=(10,11))
    nt = np.size(t_plot)
    t_plot = get_iterable(t_plot)
    tt = 1
    for tp in t_plot:
      t_inx = get_index(tp,self.t)
      z_inx = get_index(tp,self.z)
      self.t_inx = t_inx
      self.z_inx = z_inx
      #rcParams.update({'font.size': 12})

      ax1=mp.subplot(nt,1,tt)

      mp.plot(self.x/1000.,self.vp[:,z_inx,t_inx])
  #    mp.gca().set_xscale('log')
      title = 'z = ' + "{0:.0f}".format(get_iterable(self.z)[z_inx]/1000.) + ' km\nt = ' \
            +  str(get_iterable(self.t)[t_inx]/3600.) + ' hr'
      ax1.set_ylabel(title)
      mp.ylim(-0.2,0.2)

      ax2 = ax1.twinx()
      phiTmp  = self.phi[:,z_inx,t_inx]
      self.phiTmp = phiTmp
      mp.plot(self.x/1000.,phiTmp,color='r')
      for tl in ax2.get_yticklabels():
            tl.set_color('r')
#      ax2.yaxis.set_label_position("right")
      ax2.set_ylabel(r'$\phi$',color='r')

      if tt != nt:
        mp.gca().set_xticklabels([])
      else:
        mp.xlabel(r'Ground Range [km]')

      tt = tt+1

    title = r"Velocity Perturbation $v_x'$"
    mp.suptitle(title)
    mp.tight_layout()
    mp.subplots_adjust(top=0.90)

  def plotSoundProfile(self):
    mp.figure(figsize=(16/3.,8))
    #rcParams.update({'font.size': 12})

    mp.subplot(111)
    mp.plot(self.c, self.zGrid[0,:,0]/1000.)
#    mp.gca().set_xscale('log')
#    mp.gca().set_yticklabels([])
    mp.xlabel(r'Sound Speed [m/s]')
    mp.ylabel(r'Altitude [km]')

    mp.tight_layout()

  def plotPPrimePartsRange(self,z_plot,t_plot,timeUnits='minutes',xaxis='range',lengthUnits='kilometers',markRange=None):
    t_plot = np.array(t_plot)

    if timeUnits == 'minutes':
      t_plot = t_plot*60.
    elif timeUnits == 'hours':
      t_plot = t_plot*3600.

    if lengthUnits == 'kilometers':
      z_plot = z_plot * 1000.

    mp.figure(figsize=(20,11.5))
    t_inx = get_index(t_plot,self.t)
    z_inx = get_index(z_plot,self.z)
    self.t_inx = t_inx
    self.z_inx = z_inx

    xData  = self.x/1000.
    xLabel = 'Ground Range [km]'
    xmin  = np.min(xData)
    xmax  = np.max(xData)

    markStr = ''

    rows  = 5
    cols  = 2

    cp = 1
    ax = mp.subplot(rows,cols,cp)
    yData = self.ppA[:,z_inx,t_inx]
    mp.plot(xData,yData)
    mp.gca().set_xticklabels([])
    mp.gca().set_yscale('log')
    mp.ylabel(r'$|\overline{T}|$')
    if markRange != None: vline(markRange,markStr,'g')
    mp.xlim(xmin,xmax)
    mp.title('Parts of p\'/p0')
    mp.grid()

    cp = 3
    ax = mp.subplot(rows,cols,cp)
    yData = -self.ppB[:,z_inx,t_inx]
    mp.plot(xData,yData)
    mp.gca().set_xticklabels([])
    mp.gca().set_yscale('log')
    mp.ylabel(r'$-\frac{I \gamma \omega_{b1} B_{zs} t}{2 \pi c_1^2 \rho_0(z_s) x}$')
    if markRange != None: vline(markRange,markStr,'g')
    mp.xlim(xmin,xmax)
#    mp.ylim(-5,0)
    mp.grid()

    cp = 5
    ax = mp.subplot(rows,cols,cp)
    yData = self.ppC[:,z_inx,t_inx]
    mp.plot(xData,yData)
    mp.gca().set_xticklabels([])
#    mp.gca().set_yscale('log')
    mp.ylabel(r'$\exp \left[ \left(\frac{\delta z}{4 H_1}\right)^2 - \left(\frac{\omega_{b1}(t^2-t_L^2)^{1/2} \delta z}{2x}\right)^2 \right]$')
    if markRange != None: vline(markRange,markStr,'g')
    mp.xlim(xmin,xmax)
    mp.grid()

    cp = 7
    ax = mp.subplot(rows,cols,cp)
    yData = self.ppD[:,z_inx,t_inx]
    mp.plot(xData,yData)
#    mp.gca().set_xticklabels([])
#    mp.gca().set_yscale('log')
    mp.ylabel(r'$\frac{1}{\omega_{c1}(t^2-t_L^2)^{1/2} + \omega_{c2}t}$')
    if markRange != None: vline(markRange,markStr,'g')
#    mp.xlabel(xLabel)
    mp.xlim(xmin,xmax)
    mp.grid()

    cp = 9
    ax = mp.subplot(rows,cols,cp)
    yData = self.ppE[:,z_inx,t_inx]
    mp.plot(xData,yData)
#    mp.gca().set_xticklabels([])
#    mp.gca().set_yscale('log')
    mp.ylabel(r"$p'/p_0$ Envelope")
    if markRange != None: vline(markRange,markStr,'g')
    mp.xlabel(xLabel)
    mp.xlim(xmin,xmax)
    mp.ylim(-0.001,0)
    mp.grid()

    cp = 2
    ax = mp.subplot(rows,cols,cp)
    yData = self.vpCoef[:,z_inx,t_inx]
    mp.plot(xData,yData)
#    mp.gca().set_xticklabels([])
    mp.gca().set_yscale('log')
    mp.ylabel(r'$\frac{c_2^2 \overline{k}_x}{\gamma \overline{\omega}}$')
    if markRange != None: vline(markRange,markStr,'g')
#    mp.xlabel(xLabel)
    mp.title('Parts of v\'')
    mp.xlim(xmin,xmax)
    mp.grid()

    cp = 4
    ax = mp.subplot(rows,cols,cp)
    yData = self.vpCoef[:,z_inx,t_inx] * self.ppE[:,z_inx,t_inx]
    mp.plot(xData,yData)
#    mp.gca().set_xticklabels([])
#    mp.gca().set_yscale('log')
    mp.ylabel(r"$v'$ Envelope")
    if markRange != None: vline(markRange,markStr,'g')
    mp.xlabel(xLabel)
    mp.xlim(xmin,xmax)
    mp.ylim(-1,0)
    mp.grid()

    cp = 8
    ax = mp.subplot(rows,cols,cp)
    gr = 600*1000.
    x_inx = get_index(gr,self.x)
    tmpXData = np.abs(self.T[x_inx,:,t_inx])
    mp.plot(tmpXData,self.z/1000.)
#    mp.gca().set_xticklabels([])
#    mp.gca().set_yscale('log')
    mp.xlabel(r"$|\overline{T}|$")
    mp.ylabel(r'Altitude [km]')
    mp.grid()
    title = 'x = ' + "{0:.0f}".format(get_iterable(self.x)[x_inx]/1000.) + ' km; t = ' \
          +  str(get_iterable(self.t)[t_inx]/3600.) + ' hr'
    mp.title(title)

#    cp = 5
#    ax = mp.subplot(rows,cols,cp)
#    yData = self.ppD[:,z_inx,t_inx]
#    mp.plot(xData,yData)
##    mp.gca().set_xticklabels([])
##    mp.gca().set_yscale('log')
#    mp.ylabel(r'$\frac{\sin [\omega_{c1}(t^2-t_L^2)^{1/2} + \omega_{c2}t + \phi]}{\omega_{c1}(t^2-t_L^2)^{1/2} + \omega_{c2}t}$')
#    if markRange != None: vline(markRange,markStr,'g')
#    mp.xlabel(xLabel)
#    mp.xlim(np.min(xData),np.max(xData))
#    mp.grid()

    title = 'z = ' + "{0:.0f}".format(get_iterable(self.z)[z_inx]/1000.) + ' km; t = ' \
          +  str(get_iterable(self.t)[t_inx]/3600.) + ' hr'
    mp.suptitle(title)
    mp.tight_layout()
    mp.subplots_adjust(top=0.90)

  def plotSinVarsRange(self,z_plot,t_plot,timeUnits='minutes',xaxis='range',lengthUnits='kilometers',markRange=None):
    t_plot = np.array(t_plot)
    if timeUnits == 'minutes':
      t_plot = t_plot*60.
    elif timeUnits == 'hours':
      t_plot = t_plot*3600.

    if lengthUnits == 'kilometers':
      z_plot = z_plot * 1000.

    mp.figure(figsize=(20,11.5))
    t_inx = get_index(t_plot,self.t)
    z_inx = get_index(z_plot,self.z)
    self.t_inx = t_inx
    self.z_inx = z_inx

    xData  = self.x/1000.
    xLabel = 'Ground Range [km]'

    markStr = ''

    rows  = 4
    cols  = 2

    cp = 1
    ax = mp.subplot(rows,cols,cp)
#    yData = (2.*np.pi/self.omega_c1[:,z_inx,t_inx]) / 60.
    yData = self.omega_c1[:,z_inx,t_inx]
    mp.plot(xData,yData)
    mp.gca().set_xticklabels([])
#    mp.ylabel(r'$2 \pi / \omega_{c1}$ [min]')
    mp.gca().set_yscale('log')
    mp.ylabel(r'$\omega_{c1}$')
    if markRange != None: vline(markRange,markStr,'g')

    cp = 3
    ax = mp.subplot(rows,cols,cp)
#    yData = (2.*np.pi/self.omega_c2[:,z_inx,t_inx]) / 60.
    yData = self.omega_c2[:,z_inx,t_inx]
    mp.plot(xData,yData)
    mp.gca().set_xticklabels([])
#    mp.gca().set_yscale('log')
#    mp.ylabel(r'$2 \pi / \omega_{c2}$ [min]')
    mp.ylabel(r'$\omega_{c2}$')
    if markRange != None: vline(markRange,markStr,'g')

    cp = 5
    ax = mp.subplot(rows,cols,cp)
    mp.plot(xData,self.phi[:,z_inx,t_inx])
    mp.ylabel(r'$\phi$')
    mp.gca().set_xticklabels([])
    if markRange != None: vline(markRange,markStr,'g')

    cp = 7
    ax = mp.subplot(rows,cols,cp)
    mp.plot(xData,self.tGrid[:,z_inx,t_inx]/60.)
    mp.ylabel(r'$t$ [min]')
    if markRange != None: vline(markRange,markStr,'g')
    mp.xlabel(xLabel)

    cp = 2
    ax = mp.subplot(rows,cols,cp)
    mp.plot(xData,self.t_L[:,z_inx,t_inx]/60.)
    mp.gca().set_xticklabels([])
    mp.ylabel(r'$t_L$ [min]')
    if markRange != None: vline(markRange,markStr,'g')

    cp = 4
    ax = mp.subplot(rows,cols,cp)
    mp.plot(xData,self.test7[:,z_inx,t_inx]/60.)
    mp.gca().set_xticklabels([])
    mp.ylabel(r'$(t^2-t_L^2)^{1/2}$ [min]')
    if markRange != None: vline(markRange,markStr,'g')

    cp = 6
    ax = mp.subplot(rows,cols,cp)
    mp.plot(xData,self.test8[:,z_inx,t_inx])
    mp.gca().set_yscale('log')
    mp.gca().set_xticklabels([])
    mp.ylabel(r'$\omega_{c1}(t^2-t_L^2)^{1/2}$')
    if markRange != None: vline(markRange,markStr,'g')

    cp = 8
    ax = mp.subplot(rows,cols,cp)
    mp.plot(xData,self.test9[:,z_inx,t_inx])
    mp.ylabel(r'$\omega_{ct} t + \omega_{c1}(t^2-t_L^2)^{1/2} + \phi$')
    mp.gca().set_yscale('log')
    if markRange != None: vline(markRange,markStr,'g')

    mp.xlabel(xLabel)

    title = 'z = ' + "{0:.0f}".format(get_iterable(self.z)[z_inx]/1000.) + ' km; t = ' \
          +  str(get_iterable(self.t)[t_inx]/3600.) + ' hr'
    mp.suptitle(title)
    mp.tight_layout()
    mp.subplots_adjust(top=0.95)


  def plotSinVarsTime(self,z_plot,x_plot,timeUnits='minutes',lengthUnits='kilometers',markTime=None):
    if lengthUnits == 'kilometers':
      z_plot = z_plot * 1000.
      x_plot = x_plot * 1000.

    mp.figure(figsize=(20,11.5))
    x_inx = get_index(x_plot,self.x)
    z_inx = get_index(z_plot,self.z)
    self.x_inx = x_inx
    self.z_inx = z_inx

    xData = self.t
    if timeUnits == 'minutes':
      xData  = xData/60.
      xLabel = 'Time [min]'
    elif timeUnits == 'hours':
      xData = xData/3600.
      xLabel = 'Time [hr]'
    else:
      xLabel = 'Time [sec]'

    t_inx = range(len(xData))

    markStr = ''
    rows    = 4
    cols    = 2

    cp = 1
    ax = mp.subplot(rows,cols,cp)
    yData = (2.*np.pi/self.omega_c1[x_inx,z_inx,t_inx]) / 60.
    mp.plot(xData,yData)
#    mp.gca().set_yscale('log')
    mp.gca().set_xticklabels([])
    mp.ylabel(r'$2 \pi / \omega_{c1}$ [min]')
    if markTime != None: vline(markTime,markStr,'g')

    cp = 3
    ax = mp.subplot(rows,cols,cp)
    yData = (2.*np.pi/self.omega_c2[x_inx,z_inx,t_inx]) / 60.
    mp.plot(xData,yData)
#    mp.gca().set_yscale('log')
    mp.gca().set_xticklabels([])
    mp.ylabel(r'$2 \pi / \omega_{c2}$ [min]')
    if markTime != None: vline(markTime,markStr,'g')

    cp = 5
    ax = mp.subplot(rows,cols,cp)
    mp.plot(xData,self.phi[x_inx,z_inx,t_inx])
    mp.ylabel(r'$\phi$')
    if markTime != None: vline(markTime,markStr,'g')
    mp.gca().set_xticklabels([])

    cp = 7
    ax = mp.subplot(rows,cols,cp)
    mp.plot(xData,self.tGrid[x_inx,z_inx,t_inx]/60.)
    mp.ylabel(r'$t$ [min]')
    if markTime != None: vline(markTime,markStr,'g')
    mp.xlabel(xLabel)

    cp = 2
    ax = mp.subplot(rows,cols,cp)
    mp.plot(xData,self.t_L[x_inx,z_inx,t_inx]/60.)
    mp.gca().set_xticklabels([])
    mp.ylabel(r'$t_L$ [min]')
    if markTime != None: vline(markTime,markStr,'g')

    cp = 4
    ax = mp.subplot(rows,cols,cp)
    mp.plot(xData,self.test7[x_inx,z_inx,t_inx]/60.)
    mp.gca().set_xticklabels([])
    mp.ylabel(r'$(t^2-t_L^2)^{1/2}$ [min]')
    if markTime != None: vline(markTime,markStr,'g')

    cp = 6
    ax = mp.subplot(rows,cols,cp)
    mp.plot(xData,self.test8[x_inx,z_inx,t_inx])
    mp.gca().set_yscale('log')
    mp.gca().set_xticklabels([])
    mp.ylabel(r'$\omega_{c1}(t^2-t_L^2)^{1/2}$')
    if markTime != None: vline(markTime,markStr,'g')

    cp = 8
    ax = mp.subplot(rows,cols,cp)
    mp.plot(xData,self.test9[x_inx,z_inx,t_inx])
    mp.ylabel(r'$\omega_{ct} t + \omega_{c1}(t^2-t_L^2)^{1/2} + \phi$')
    mp.gca().set_yscale('log')
    if markTime != None: vline(markTime,markStr,'g')

    mp.xlabel(xLabel)

    title = 'z = ' + "{0:.0f}".format(get_iterable(self.z)[z_inx]/1000.) + ' km; x = ' + "{0:.0f}".format(get_iterable(self.x)[x_inx]/1000.) + ' km'
    mp.suptitle(title)
    mp.tight_layout()
    mp.subplots_adjust(top=0.95)
