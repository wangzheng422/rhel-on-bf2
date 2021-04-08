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
    print("Warning: Number of specified core is less than number of irqs: %s < %s" % (len(cores), len(irqs)))
    print("         Will use specified cores in round-robin fashion.")

  while len(cores) < len(irqs):
    cores = cores + cores

  for i, c in zip(irqs, cores):
    path = "/proc/irq/%s/smp_affinity" % i
    with open(path, "w") as f:
      print("Setting affinity of irq %s to core %d" % (i, c))
      hex_code = hex(1 << c)[2:]
      final = ""
      added = 0
      for i in range(len(hex_code)):
          final = hex_code[len(hex_code) - 1 - i] + final
          added += 1
          if added % 8 == 0 and i != len(hex_code) - 1:
            final = "," + final
      print(final)
      f.write(final)

def count_irq(dev):
  def is_int(s):
    try:
        int(s)
        return True
    except ValueError:
        return False

  irqs = get_irqs(dev)
  irqs = dict(zip(irqs, [0]*len(irqs)))

  with open("/proc/interrupts", "r") as f:
    for e in f.readlines():
      irq = e.split(":")[0].strip()
      if irq in irqs.keys():
        count = sum(map(int, filter(is_int, str(e.split(":")[1]).split())))
        irqs[irq] = count

  for k,v in irqs.items():
    print("%s: %s" %(k, v))

def main():
  if len(sys.argv) != 2:
    print("usage: %s interface" % sys.argv[0])
    print("       Shows the number of interrupts that have")
    print("       fired for a specific network device")
    sys.exit(0)

  count_irq(sys.argv[1])

main()

