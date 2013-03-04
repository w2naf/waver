import numpy as np
a = np.arange(6).reshape(2,3)
b = np.arange(6).reshape(2,3) * 10.
it = np.nditer([a,b])

while not it.finished:
  print it[0], it[1]
  it.iternext()
