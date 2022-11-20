#!/bin/bash
# Set folder names
timeStamp=$(date '+%Y-%m-%d_%H-%M-%S')
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


# Snapshot into "current" folder
btrfs subvolume snapshot -r /home ${snapDir}/home-current
btrfs subvolume snapshot -r / ${snapDir}/root-current
btrfs subvolume snapshot -r /mnt/diskRoot/plexmediaserver/ ${snapDir}/plex-current

# Also snapshot as dated
btrfs subvolume snapshot -r ${snapDir}/home-current ${snapDir}/${homeSnapName}
btrfs subvolume snapshot -r ${snapDir}/root-current ${snapDir}/${rootSnapName}
btrfs subvolume snapshot -r ${snapDir}/plex-current ${snapDir}/${plexSnapName}

# RAID snapshots. Bad Idea
#btrfs subvolume snapshot -r ${raidDir}/public ${raidSnapDir}/${publicSnapName}
#btrfs subvolume snapshot -r ${raidDir}/tyler ${raidSnapDir}/${tylerSnapName}
#btrfs subvolume snapshot -r ${raidDir}/meagan ${raidSnapDir}/${meaganSnapName}


# Rsync the "current" home backup
# rsync -avh --delete ${snapDir}/home-current $backupDir
# rsync -avh --delete ${snapDir}/root-current $backupDir


echo "Creating Root Tarball..."
cd $snapDir
tar \
	-caf ${snapDir}/${rootSnapName}.tar.xz \
	--checkpoint=10000 \
	--checkpoint-action=echo="Root: #%u: %T" \
	${rootSnapName} 
mv ${snapDir}/${rootSnapName}.tar.xz ${backupDir}/

echo "Creating PLEX Tarball..."
tar \
	--exclude=${plexSnapName}/'Library/Application Support/Plex Media Server/Cache' \
	-caf ${snapDir}/${plexSnapName}.tar.xz \
	--checkpoint=10000 \
	--checkpoint-action=echo="PLEX: #%u: %T" \
	${plexSnapName}
mv ${snapDir}/${plexSnapName}.tar.xz ${backupDir}/

echo "Creating tyler Tarball..."
cd ${homeSnapName}
tar \
	--exclude='tyler/.cache' \
	-caf ${snapDir}/${tylerSnapName}.tar.xz \
	tyler
mv ${snapDir}/${tylerSnapName}.tar.xz ${backupDir}/


echo "Creating meagan Tarball..."
tar -caf ${snapDir}/${meaganSnapName}.tar.xz meagan
mv ${snapDir}/${meaganSnapName}.tar.xz ${backupDir}/
 

# Delete current backup
btrfs subvolume delete ${snapDir}/home-current
btrfs subvolume delete ${snapDir}/root-current
btrfs subvolume delete ${snapDir}/plex-current
