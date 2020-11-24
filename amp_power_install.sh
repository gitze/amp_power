#!/bin/sh -x 
#get all files into following directory:

if ! [ -d /mnt/mmcblk0p2/tce/amp_power/ ]; then
	echo "initialize directory"
	mkdir /mnt/mmcblk0p2/tce/amp_power/
fi
cd /mnt/mmcblk0p2/tce/amp_power/

wget -O amp_power.newversion http://diskstation/amp_power/amp_power.version
if [ -f amp_power.version ]; then
	echo "compare versions"
	if diff -q amp_power.version amp_power.newversion; then
		exit
	fi
fi
echo "install new version"
wget -O amp_power http://diskstation/amp_power/amp_power.sh
wget -O amp_power.version http://diskstation/amp_power/amp_power.version.txt
wget -O amp_power_initd http://diskstation/amp_power/amp_power_initd.txt
wget -O bootlocal.sh.patch http://diskstation/amp_power/bootlocal.sh.patch



#######
# Last fixes, Patch bootlocal.sh & run Backup
#######
echo "patch Environment"
cd /opt && sudo patch < /mnt/mmcblk0p2/tce/amp_power/bootlocal.sh.patch && sudo filetool.sh -b
chmod 775 /mnt/mmcblk0p2/tce/amp_power/amp_power
chmod 775 /mnt/mmcblk0p2/tce/amp_power/amp_power_initd
sudo filetool.sh -b

/mnt/mmcblk0p2/tce/amp_power/amp_power_initd restart