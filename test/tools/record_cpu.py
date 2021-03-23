import subprocess
import sys
import time

def run_mpstat():
    result = subprocess.run(["mpstat", '-P', "ALL", "10", "1"], stdout=subprocess.PIPE)
    return result.stdout.decode("utf-8")

def list_to_ints(ids):
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


def get_cpu():
    ret = []
    r = run_mpstat()
    p = False
    skip_lines = 2
    names = ["cpu", "usr", "nice", "sys", "iowait", "irq", "soft", "steal", "guest", "gnice", "idle"]
    for e in r.split("\n"):
        if e.startswith("Average: "):
            e = e.strip("Average: ")
            if skip_lines == 0:
                parts = e.split()
                cpu = int(parts[0])
                other = list(map(float, parts[1:]))
                ret.append(dict(zip(names, [cpu] + other)))
            else:
                skip_lines -= 1
    return ret

def run_indef():
    first = True
    while True:
        elements = get_cpu()
        elements = list(elements)
        if first:
            first = False
            print("time" + "," + ",".join(["cpu%s" % x for x in range(len(elements))]))
        print(str(time.time()) + "," + ",".join([x["idle"] for x in elements]))

def get_current_total_util(l):
    stats = get_cpu()
    tot_all = 0
    li = list_to_ints(l)
    for e in stats:
        if e["cpu"] in li:
            tot_all += 100 - e["idle"]

    print(tot_all)

get_current_total_util(sys.argv[1])

