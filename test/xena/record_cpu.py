import subprocess
import time

def run_mpstat():
    result = subprocess.run(["mpstat", '-P', "ALL", "1", "1"], stdout=subprocess.PIPE)
    return result.stdout.decode("utf-8")

def get_cpu():
    ret = []
    r = run_mpstat()
    p = False
    skip_lines = 2
    for e in r.split("\n"):
        if e.startswith("Average: "):
            if skip_lines == 0:
                ret.append(10000-int(float(e.split(" ")[-1])*100))
            else:
                skip_lines -= 1
    return ret

first = True
while True:
    elements = map(lambda x: str(x//100) + "." + str(x % 100), get_cpu())
    elements = list(elements)
    if first:
        first = False
        print("time" + "," + ",".join(["cpu%s" % x for x in range(len(elements))]))

    print(str(time.time()) + "," + ",".join(elements))
