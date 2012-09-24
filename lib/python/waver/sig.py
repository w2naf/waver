class attrdict(dict):
  def __getattr__(self, attr):
    return self[attr]
  def __setattr__(self, attr, value):
    self[attr] = value

class sig(object):
  def __init__(self, dtv, data, **metadata):
    """Define a vtsd sig object.

    :param dtv: datetime.datetime list
    :param data: raw data
    :param ylabel: Y-Label String for data
    :returns: sig object
    """
    defaults = attrdict({})
    defaults.ylabel = 'Untitled Y-Axis'
    defaults.xlabel = 'Time [UT]'
    defaults.title  = 'Untitled Plot'

    self.metadata = attrdict(defaults.items() + metadata.items())
    self.items = metadata.items()

    self.raw = sigStruct(dtv, data, parent=self)

class sigStruct(sig):
  def __init__(self, dtv, data, parent=0, **metadata):
    self.parent = parent
    """Define a vtsd sigStruct object.

    :param dtv: datetime.datetime list
    :param data: raw data
    :param ylabel: Y-Label String for data
    :returns: sig object
    """
    self.dtv      = dtv
    self.data     = data
    self.metadata = attrdict({})

    for key in metadata:
      print "%s: %s" % (key, metadata[key])

    for key in metadata:
      self.metadata[key] = metadata[key]

  def plot(self):
    from matplotlib import pyplot as mp

    metadata = attrdict(self.parent.metadata.items() + self.metadata.items())

    fig = mp.figure()
    mp.plot(self.dtv,self.data)
    fig.autofmt_xdate()

    if 'dtStart' in metadata:
      mp.xlim(xmin=metadata.dtStart)
    if 'dtEnd' in metadata:
      mp.xlim(xmax=metadata.dtEnd)

    mp.xlabel(metadata.xlabel)
    mp.ylabel(metadata.ylabel)
    mp.title(metadata.title)

    return super(sigStruct, self)
