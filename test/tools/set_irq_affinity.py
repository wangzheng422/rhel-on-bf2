import os, sys

def list_to_ints(ids):
  def list_to_val(l):
    val = 0
    for e in list_to_ints(l):
      val = val | (1 << e)
    return val

  ret = []

  for e in ids.split(","):
    if "-" in e:
      start, stop = e.split("-")
    else:
      start = stop = e
    start, stop = int(start), int(stop)
    for i in range(start, stop + 1):
      ret.append(i)
  return ret

def get_irqs(dev):
  path = "/sys/class/net/%s/device/msi_irqs/" % dev
  return os.listdir(path)

def set_irq(dev, cores):
  irqs = get_irqs(dev)
  cores = list_to_ints(cores)

  if len(cores) < len(irqs):
    print("Number of cores is less than number of irqs: %s < %s" % (len(cores), len(irqs)))
    sys.exit(-1)

  for i, c in zip(irqs, cores):
    path = "/proc/irq/%s/smp_affinity" % i
    with open(path, "w") as f:
      print("Setting affinity of irq %s to core %d" % (i, c))
      f.write(hex(c)[2:])

def query_irq(dev):
  irqs = get_irqs(dev)
  for i in irqs:
    path = "/proc/irq/%s/smp_affinity" % i
    with open(path, "r") as f:
        print("%s: %s" % (i, f.read().strip()))

def main():
  if len(sys.argv) != 3 and len(sys.argv) != 2:
    print("usage: %s interface [core_list]" % sys.argv[0])
    print("       If you don't specifiy core_list, the affinity")
    print("       of all irqs will simply be listed")
    sys.exit(0)

  if len(sys.argv) == 2:
    query_irq(sys.argv[1])
  else:
    set_irq(sys.argv[1], sys.argv[2])

main()

