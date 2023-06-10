#!/bin/bash
# Set folder names
timeStamp=$(date '+%Y-%m-%d_%H-%M-%S')
homeSnapName=home-${timeStamp}
rootSnapName=root-${timeStamp}
plexSnapName=plex-${timeStamp}
libVirtSnapName=libvirt-images-${timeStamp}
vms_snap_name=vms_${timeStamp}
publicSnapName=public-${timeStamp}
tylerSnapName=tyler-${timeStamp}
meaganSnapName=meagan-${timeStamp}
machinesSnapName=machines-${timeStamp}

snapDir=/mnt/snapshots
raidDir=/mnt/RAID
raidSnapDir=${raidDir}/snapshots
backupDir=/mnt/RAID/tyler/fileserver

# XZ Multithread
export XZ_DEFAULTS="-T 3"


# Snapshot into "current" folder
btrfs subvolume snapshot -r /home ${snapDir}/home-current
btrfs subvolume snapshot -r / ${snapDir}/root-current
btrfs subvolume snapshot -r /mnt/diskRoot/plexmediaserver/ ${snapDir}/plex-current
# btrfs subvolume snapshot -r /mnt/diskRoot/libvirt-images/ ${snapDir}/libvirt-images-current
btrfs subvolume snapshot -r /home/tyler/vms/ ${snapDir}/vms
btrfs subvolume snapshot -r /var/lib/machines/ ${snapDir}/machines-current

# Also snapshot as dated
btrfs subvolume snapshot -r ${snapDir}/home-current ${snapDir}/${homeSnapName}
btrfs subvolume snapshot -r ${snapDir}/root-current ${snapDir}/${rootSnapName}
btrfs subvolume snapshot -r ${snapDir}/plex-current ${snapDir}/${plexSnapName}
btrfs subvolume snapshot -r ${snapDir}/machines-current ${snapDir}/${machinesSnapName}

# RAID snapshots. Bad Idea
#btrfs subvolume snapshot -r ${raidDir}/public ${raidSnapDir}/${publicSnapName}
#btrfs subvolume snapshot -r ${raidDir}/tyler ${raidSnapDir}/${tylerSnapName}
#btrfs subvolume snapshot -r ${raidDir}/meagan ${raidSnapDir}/${meaganSnapName}


# Rsync the "current" home backup
# rsync -avh --delete ${snapDir}/home-current $backupDir
# rsync -avh --delete ${snapDir}/root-current $backupDir


cd $snapDir
echo "Creating Root Tarball..."
tar \
	--warning=no-file-ignored \
	-cf - ${rootSnapName} -P | \
	pv -s $(du -sb ${rootSnapName} | awk '{print $1}') | \
	xz > ${snapDir}/${rootSnapName}.tar.xz 

echo "Finished!"
echo "Moving Root Tarball..."
mv ${snapDir}/${rootSnapName}.tar.xz ${backupDir}/
echo "Finished!"

echo "Creating PLEX Tarball..."
tar \
	--exclude=${plexSnapName}/'Library/Application Support/Plex Media Server/Cache' \
	--warning=no-file-ignored \
	-cf - ${plexSnapName} -P | \
	pv -s $(du -sb ${plexSnapName} | awk '{print $1}') | \
	xz > ${snapDir}/${plexSnapName}.tar.xz 
echo "Finished!"

echo "Moving PLEX Tarball..."
mv ${snapDir}/${plexSnapName}.tar.xz ${backupDir}/
echo "Finished!"

echo "Creating machines Tarball..."
tar \
	-cf - ${machinesSnapName} -P | \
	pv -s $(du -sb ${machinesSnapName} | awk '{print $1}') | \
	xz > ${snapDir}/${machinesSnapName}.tar.xz
echo "Finished!"

echo "Moving machines Tarball..."
mv ${snapDir}/${machinesSnapName}.tar.xz ${backupDir}/
echo "Finished!"

echo "Creating tyler Tarball..."
cd ${homeSnapName}
tar \
	--exclude='tyler/.cache' \
	-cf - tyler -P | \
	pv -s $(du -sb tyler | awk '{print $1}') | \
	xz > ${snapDir}/${tylerSnapName}.tar.xz 
echo "Finished!"

echo "Moving tyler Tarball..."
mv ${snapDir}/${tylerSnapName}.tar.xz ${backupDir}/
echo "Finished!"


echo "Creating meagan Tarball..."
tar -caf ${snapDir}/${meaganSnapName}.tar.xz meagan
echo "Finished!"

echo "Moving meagan Tarball..."
mv ${snapDir}/${meaganSnapName}.tar.xz ${backupDir}/
echo "Finished!"


#echo "Rsyncing libvirt images..."
#rsync -avh --progress ${snapDir}/libvirt-images-current/ ${raidDir}/VMs/libvirt-images/
#chown -R tyler ${raidDir}/VMs/
#chgrp -R tyler ${raidDir}/VMs/

echo "Rsyncing VM images..."
rsync -avh --progress ${snapDir}/vms/ ${raidDir}/VMs/
chown -R tyler ${raidDir}/VMs/
chgrp -R tyler ${raidDir}/VMs/
echo "Finished!"

echo "Cleaning up..."
# Delete current backup
btrfs subvolume delete ${snapDir}/home-current
btrfs subvolume delete ${snapDir}/root-current
btrfs subvolume delete ${snapDir}/plex-current
#btrfs subvolume delete ${snapDir}/libvirt-images-current
btrfs subvolume delete ${snapDir}/vms
echo "Finished!"
