Helper scripts for booting Red Hat Enterprise Linux 8 on the NVIDIA Bluefield 2 DPU
====

These scripts are based off the work of Red Hat, specifically @ecohen, @egarver, @fdangelo, @bnemeth and others. To see the full git history, please use `git log --follow <filename>`.

The purpose of the provided scripts and Kickstart file is to enable the boot and installation of [RHEL 8.4](https://www.redhat.com/en/technologies/linux-platforms/enterprise-linux) on the [NVIDIA Bluefield 2 DPU](https://www.nvidia.com/content/dam/en-zz/Solutions/Data-Center/documents/datasheet-nvidia-bluefield-2-dpu.pdf).

Prerequisites:
---

* 64bit Red Hat or CentOS host computer
* BF2 card physically installed and connected
* Red Hat Enterprise Linux >=8.4 iso downloaded on the host computer

Quick and dirty installation:
---

```
$ git clone https://github.com/kwozyman/rhel-on-bf2
$ cd rhel-on-bf2
$ export RHEL_ISO=/path/to/redhat_iso_file
$ sh bluefiled_provision.sh -a
```

The `-a` switch will run, in order:

* Host preparation / dependency install (`-i`)
* Update BF2 firmware (`-f`)
* Check (and enable) [SR-IOV](https://en.wikipedia.org/wiki/Single-root_input/output_virtualization) support on the host system
* Prepare PXE and run PXE install (`-p`)

After following the onscreen instructions, RHEL installation should start and you would end up with a rather standard RHEL installation with the root password of `bluefield`.

What is the actual process?
---

First, we need to install software dependencies for the card. These include the [Mellanox rshim driver](https://github.com/Mellanox/rshim) and the [Mellanox firmware bruning tools](https://github.com/Mellanox/mstflint). The provision script's dependencies are: expect, wget and minicom

Second, the firmware is updated to a hardcoded version of `BlueField-3.5.1.11601`.

The host is then prepared as a PXE boot host, partly following [this documentation from Red Hat](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html-single/performing_an_advanced_rhel_installation/index#preparing-for-a-network-install_installing-rhel-as-an-experienced-user) so in the end we will have running `dhcpd`, `(t)ftp` and `httpd` servers with the kernel extracted from the iso file, PXE and Grub menus prepared.

`minicom` is then used to attach to the card's console and some simple `expect` rules navigate the menus as much as possible. Please note that one needs to manually select the 'PXE boot' option from the menu, as instructed by the onscreen prompts in the script, as it is not possible to predict the position of that particular menu item.

For the installation start, the `RHEL8-bluefield.ks` Kickstart file is used and should provide you at the end with a rather default RHEL install.
