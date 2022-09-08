#!/bin/bash
# Set folder names
timeStamp=$(date +'%Y%m%d-%T')
homeSnapName=home-${timeStamp}
rootSnapName=root-${timeStamp}
plexSnapName=plex-${timeStamp}
publicSnapName=public-${timeStamp}
tylerSnapName=tyler-${timeStamp}
meaganSnapName=meagan-${timeStamp}

snapDir=/mnt/snapshots
raidDir=/mnt/RAID
raidSnapDir=${raidDir}/snapshots
backupDir=/mnt/RAID/tyler/fileserver

# XZ Multithread
export XZ_DEFAULTS="-T 3"


#Snapshot into "current" folder
btrfs subvolume snapshot -r /home ${snapDir}/home-current
btrfs subvolume snapshot -r / ${snapDir}/root-current
btrfs subvolume snapshot -r /var/lib/plexmediaserver ${snapDir}/plex-current

# Also snapshot as dated
#btrfs subvolume snapshot -r ${snapDir}/home-current ${snapDir}/${homeSnapName}
#btrfs subvolume snapshot -r ${snapDir}/root-current ${snapDir}/${rootSnapName}
#btrfs subvolume snapshot -r ${snapDir}/plex-current ${snapDir}/${plexSnapName}
#btrfs subvolume snapshot -r ${raidDir}/public ${raidSnapDir}/${publicSnapName}
#btrfs subvolume snapshot -r ${raidDir}/tyler ${raidSnapDir}/${tylerSnapName}
#btrfs subvolume snapshot -r ${raidDir}/meagan ${raidSnapDir}/${meaganSnapName}


# Rsync the "current" home backup
# rsync -avh --delete ${snapDir}/home-current $backupDir
# rsync -avh --delete ${snapDir}/root-current $backupDir


echo "Creating Root Tarball..."
cd $snapDir
tar \
	-caf ${snapDir}/root-current.tar.xz \
	--checkpoint=10000 \
	--checkpoint-action=echo="Root: #%u: %T" \
	root-current 
mv ${snapDir}/root-current.tar.xz ${backupDir}/

echo "Creating PLEX Tarball..."
tar --exclude='plex-current/Library/Application Support/Plex Media Server/Cache' -caf ${snapDir}/plex-current.tar.xz --checkpoint=10000 --checkpoint-action=echo="PLEX: #%u: %T" plex-current
mv ${snapDir}/plex-current.tar.xz ${backupDir}/

echo "Creating tyler Tarball..."
cd home-current/
tar --exclude='tyler/.cache' -caf ${snapDir}/tyler.tar.xz tyler
mv ${snapDir}/tyler.tar.xz ${backupDir}/

#echo "Creating retroarch Tarball..."
#tar --exclude='retroarch/.cache' -caf ${snapDir}/retroarch.tar.xz retroarch
#mv ${snapDir}/retroarch.tar.xz ${backupDir}/

echo "Creating meagan Tarball..."
tar -caf ${snapDir}/meagan.tar.xz meagan
mv ${snapDir}/meagan.tar.xz ${backupDir}/
 

# Delete current backup
btrfs subvolume delete ${snapDir}/home-current
btrfs subvolume delete ${snapDir}/root-current
btrfs subvolume delete ${snapDir}/plex-current
