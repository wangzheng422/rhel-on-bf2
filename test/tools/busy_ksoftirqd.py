import sys
import subprocess
import time
import glob


def read_contents(fn):
    with open(fn, "r") as f:
        return f.readlines()[0].strip()

def get_tick_hz():
    with subprocess.Popen(["getconf", "CLK_TCK"], stdout=subprocess.PIPE) as proc:
        return int(proc.stdout.readline().decode("utf-8"))

def get_ksoftirqd_pids():
    pids = []
    for e in glob.glob("/proc/*/comm"):
        if "ksoftirqd" in read_contents(e):
            pids.append(e.split("/")[2])
    return pids

def measure(pids):
    measurements = {}
    for e in pids:
        elements = read_contents("/proc/%s/stat" % e).split()
        utime = elements[13]
        stime = elements[14]
        measurements[e] = (utime, stime, elements[1])
    return measurements

def main():
    sleep_time = 1
    if len(sys.argv) > 1:
        sleep_time = int(sys.argv[1])

    pids = get_ksoftirqd_pids()

    m1 = measure(pids)
    time.sleep(sleep_time)
    m2 = measure(pids)

    for e in pids:
        if m1[e] != m2[e]:
            print(m1[e][-1])

if __name__ == "__main__":
    main()