import time, os, sys

dev = sys.argv[1]

def read_all(fn):
    with open(fn, "r") as f:
        return int(f.read().strip())

def with_unit(v):
    if (v < 1e3):
        return v, ""
    elif (v < 1e6):
        return round(v/1e3,2), "K"
    elif (v < 1e9):
        return round(v/1e6, 2), "M"
    else:
        return round(v/1e9, 2), "G"

rx_path = "/sys/class/net/%s/statistics/rx_bytes" % dev
tx_path = "/sys/class/net/%s/statistics/tx_bytes" % dev

t = time.time()
rx_tot = read_all(rx_path)
tx_tot = read_all(tx_path)
while True:
    time.sleep(1)
    t2 = time.time()
    rx_tot2 = read_all(rx_path)
    tx_tot2 = read_all(tx_path)
    rx_bps = int((rx_tot2 - rx_tot) / (t2 - t) * 8)
    tx_bps = int((tx_tot2 - tx_tot) / (t2 - t) * 8)
    rx, rx_u = with_unit(rx_bps)
    tx, tx_u = with_unit(tx_bps)
    rx_tot = rx_tot2
    tx_tot = tx_tot2
    t = t2
    print("RX: %s %sbits/sec, TX: %s %sbits/sec" % (rx, rx_u, tx, tx_u))
