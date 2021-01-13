#!/usr/bin/env python

import sys
import time
import logging

try:
    from xenalib.XenaSocket import XenaSocket
    from xenalib.XenaManager import XenaManager
    from xenalib.StatsCSV import write_csv
except:
    printf("Install XenaPythonLib as follows:")
    printf("git clone https://github.com/fleitner/XenaPythonLib")
    printf("cd XenaPythonLib")
    printf("python setup.py install --user")
    sys.exit(-1)

try:
    import scapy.layers.inet as inet
    import scapy.utils as utils
except:
    print("Install scapy first")
    sys.exit(-1)

logging.basicConfig(level=logging.INFO)


def build_test_packet():
    logging.info("Packet: Using scapy to build the test packet")
    L2 = inet.Ether(src="52:54:00:C6:10:10", dst="04:3f:72:f4:49:44")
    L3 = inet.IP(src="192.168.1.102", dst="192.168.1.101")
    L4 = inet.UDP(sport=1234, dport=1234)
    payload = "X"*22
    packet = L2/L3/L4/payload
    packet_hex = '0x' + bytes(packet).hex()
    # Uncomment below to see the packet in wireshark tool
    # utils.wireshark(packet)

    logging.debug("Packet string: %s", packet_hex)
    return packet_hex

def main():
    # create the test packet
    pkthdr = build_test_packet()
    # create the communication socket
    xsocket = XenaSocket('10.19.188.64')
    if not xsocket.connect():
        sys.exit(-1)

    # create the manager session
    xm = XenaManager(xsocket, 'user1', "xena")

    # add port 0 and configure
    port0 = xm.add_port(4, 0)
    if not port0:
        print("Failed to add port")
        sys.exit(-1)

    port0.set_pause_frames_off()
    # add port 1 and configure
    port1 = xm.add_port(4, 1)
    if not port1:
        print("Failed to add port")
        sys.exit(-1)

    port1.set_pause_frames_off()

    # add a single stream and configure
    s1_p0 = port0.add_stream(1)
    s1_p0.set_stream_on()
    s1_p0.disable_packet_limit()
    s1_p0.set_rate_fraction()
    s1_p0.set_packet_header(pkthdr)
    s1_p0.set_packet_length_fixed(64, 1518)
    s1_p0.set_packet_payload_incrementing('0x00')
    s1_p0.disable_test_payload_id()
    s1_p0.set_frame_csum_on()

    # start the traffic
    port0.start_traffic()
    time.sleep(4)

    # fetch stats
    for i in range(20):
        port0.grab_all_rx_stats()
        time.sleep(1)

    # stop traffic
    port0.stop_traffic()

    full_stats = port0.dump_all_rx_stats()

    time_points = sorted(full_stats.keys())

    for t in time_points:
        print(str(t) + "," + str(full_stats[t]["pr_notpld"]["pps"]))

    del xm
    del xsocket

if __name__ == '__main__':
    main()
