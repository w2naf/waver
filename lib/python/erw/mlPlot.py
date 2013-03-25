import numpy as np
from matplotlib import pyplot as mp

def numstr(number,d=0):
  return ("{0:."+str(d)+"f}").format(number)

def mvWin(pos="+0+0"):
  mp.get_current_fig_manager().window.wm_geometry(pos)

def xtTitle(x,t):
  tt = t[0] / 60.
  if tt < 60.:
    tt_ = 't = ' + numstr(tt) + ' min'
  else:
    tt_ = 't = ' + numstr(tt/60.,2) + ' hr'
  return 'x = ' + numstr(x[0]/1000.) + ' km; ' + tt_

def winTitle(title,adj=0.90):
  fig = mp.gcf()
  fig.canvas.set_window_title(title)

  mp.suptitle(title)
  mp.tight_layout()
  mp.subplots_adjust(top=adj)

  mvWin()

def plotRealImag(x,z,t,plotData,nRows,nCols,title=None,figsize=(20,11.5)):
  mp.figure(figsize=(figsize))
#    #rcParams.update({'font.size': 12})

  zp = z/1000.
  ylim    = None
  ylabel  = 'Altitude [km]'

#    upperTitle = r'Upgoing Wave $\lambda_z=$'   + "{0:.0f}".format(lm_up) + ' km'
#    lowerTitle = r'Downgoing Wave $\lambda_z=$' + "{0:.0f}".format(lm_dn) + ' km'

  pl = 0
  for pd in plotData:
    pl = pl + 1
    mp.subplot(nRows,nCols,pl)
    xData = np.real(pd[0])
    yData = zp
    mp.plot(xData,yData)
  #    mp.gca().set_xscale('log')
    mp.ylabel(ylabel)
    mp.xlabel(r"$\Re\left{"+pd[1]+r"\right}$")
    mp.ylim(ylim)
    xfm = mp.gca().xaxis.get_major_formatter()
    xfm.set_powerlimits([ -3, 3])

    ax2 = mp.gca().twiny()
    xData = np.imag(pd[0])
    yData = zp
    mp.plot(xData,yData,color='r')
    for tl in ax2.get_xticklabels():
          tl.set_color('r')
#    ax2.set_xlabel(r"$\Im"+pd[1]+"$",color='r')
    xfm = mp.gca().xaxis.get_major_formatter()
    xfm.set_powerlimits([ -3, 3])

  xt = xtTitle(x,t)
  title = '\n'.join([title,xt])
  winTitle(title)
  

def plotLayerWaves(x,z,t,uz_pr_up,uz_pr_dn,chi_pr_up,chi_pr_dn):
  plotData = [
    (uz_pr_up,r"u'_{z+}"),
    (uz_pr_dn,r"u'_{z-}"),
    (chi_pr_up,r"\chi'_{z+}"),
    (chi_pr_dn,r"\chi'_{z-}")
    ]
  title = 'Boundary Condition Waves'
  nRows,nCols = (1,4)
  plotRealImag(x,z,t,plotData,nRows,nCols,title=title)

def plotPolarization(x, z, t, A_x_dn, A_z_dn, A_T_dn, A_p_dn, A_chi_dn, A_x_up, A_z_up, A_T_up, A_p_up, A_chi_up):
  plotData = [
    (A_x_up,r"A'_{x+}"),
    (A_z_up,r"A'_{z+}"),
    (A_T_up,r"A'_{T+}"),
    (A_p_up,r"A'_{p+}"),
    (A_chi_up,r"A'_{\chi+}"),
    (A_x_dn,r"A'_{x-}"),
    (A_z_dn,r"A'_{z-}"),
    (A_T_dn,r"A'_{T-}"),
    (A_p_dn,r"A'_{p-}"),
    (A_chi_dn,r"A'_{\chi-}")
    ]
  title = 'Polarization Parameters'
  nRows,nCols = (2,5)
  plotRealImag(x,z,t,plotData,nRows,nCols,title=title)

def plotParams(x,z,t,omega,k_x,k_z_up,k_z_dn):
  plotData = [
    (omega,r"\overline{\omega}"),
    (k_x,r"\overline{k}_x"),
    (k_z_up,r"k_{z+}"),
    (k_z_dn,r"k_{z-}"),
    ]
  title = 'Wave Parameters'
  nRows,nCols = (1,4)
  plotRealImag(x,z,t,plotData,nRows,nCols,title=title)

def plotKz(x,z,t,all_k_z,k_z_up,k_z_dn,root_used):

  kz00 = [kk[0][0] for kk in all_k_z]
  kz01 = [kk[0][1] for kk in all_k_z]
  kz10 = [kk[1][0] for kk in all_k_z]
  kz11 = [kk[1][1] for kk in all_k_z]
  kz20 = [kk[2][0] for kk in all_k_z]
  kz21 = [kk[2][1] for kk in all_k_z]

  ru0 = (np.where(root_used == 0))[0]
  ru1 = (np.where(root_used == 1))[0]
  ru2 = (np.where(root_used == 2))[0]

  plotData = [
      (kz00,r"k_{z00}",ru0),
      (kz10,r"k_{z10}",ru1),
      (kz20,r"k_{z20}",ru2),
      (k_z_up,r"k_{z+}",None),
      (kz01,r"k_{z01}",ru0),
      (kz11,r"k_{z11}",ru1),
      (kz21,r"k_{z21}",ru2),
      (k_z_dn,r"k_{z-}",None)
      ]

  title = "All Vertical Wave Numbers"

#  plotData = [
#      (k_z_all[:][0][0]


  figsize = (20,11.5)
  mp.figure(figsize=(figsize))
#    #rcParams.update({'font.size': 12})
  zp      = z/1000.
  ylim    = None
  ylabel  = 'Altitude [km]'

#    upperTitle = r'Upgoing Wave $\lambda_z=$'   + "{0:.0f}".format(lm_up) + ' km'
#    lowerTitle = r'Downgoing Wave $\lambda_z=$' + "{0:.0f}".format(lm_dn) + ' km'

  nRows, nCols = (2,4)
  pl = 0
  for pd in plotData:
    pl = pl + 1
    mp.subplot(nRows,nCols,pl)
    xData = np.real(pd[0])
    yData = zp
    mp.plot(xData,yData,color='b')
  #    mp.gca().set_xscale('log')

    if pd[2] != None:
      mp.plot(xData[pd[2]],yData[pd[2]],'b^')
    mp.ylabel(ylabel)
    mp.xlabel(r"$\Re\left{"+pd[1]+r"\right}$")
    mp.ylim(ylim)
    xfm = mp.gca().xaxis.get_major_formatter()
    xfm.set_powerlimits([ -3, 3])

    ax2 = mp.gca().twiny()
    xData = np.imag(pd[0])
    yData = zp
    mp.plot(xData,yData,color='r')
    if pd[2] != None:
      mp.plot(xData[pd[2]],yData[pd[2]],'r^')
    for tl in ax2.get_xticklabels():
          tl.set_color('r')
#    ax2.set_xlabel(r"$\Im"+pd[1]+"$",color='r')
    xfm = mp.gca().xaxis.get_major_formatter()
    xfm.set_powerlimits([ -3, 3])

  xt = xtTitle(x,t)
  title = '\n'.join([title,xt])
  winTitle(title)
