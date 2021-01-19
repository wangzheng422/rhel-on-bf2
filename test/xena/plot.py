import matplotlib.pyplot as plt
import pandas

df = pandas.read_csv("traffic.csv")

fig, axs = plt.subplots(3)
fig.tight_layout()

first_time = min(df["time"])
last_time = max(df["time"])

axs[0].set_title("Throughput")
axs[0].plot(df["time"] - first_time, df["pps"]/1000000)
axs[0].set_ylim([0,20])
axs[0].set_ylabel("Throughput (Mpps)")
axs[0].set_xlabel("Time (s)")



df = pandas.read_csv("host_cpu.csv")

axs[1].set_title("Host CPU")
legend = []
for e in filter(lambda x: x != "time", df.columns):
    axs[1].plot(df["time"] - first_time, df[e])
    axs[1].set_ylim([0,110])
    axs[1].set_xlim([first_time - first_time, last_time - first_time])

    legend.append(e)
# axs[1].legend(legend)
axs[1].set_ylabel("CPU Util (%)")
axs[1].set_xlabel("Time (s)")


df = pandas.read_csv("bf2_cpu.csv")

axs[2].set_title("BlueField 2 CPU")
legend = []
for e in filter(lambda x: x != "time", df.columns):
    axs[2].plot(df["time"]+5 - first_time, df[e]) # +5 to sync
    axs[2].set_ylim([0,110])
    axs[2].set_xlim([first_time - first_time, last_time - first_time])
    legend.append(e)
# axs[2].legend(legend)

axs[2].set_ylabel("CPU Util (%)")
axs[2].set_xlabel("Time (s)")

plt.show()