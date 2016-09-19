#!/bin/bash
OLDSNAP="AutoD-"`date +"%F" --date='-2 day'`
NEWSNAP="AutoD-"`date +"%F"`
RECV="backuptank"
SEND="datatank"

RECV_IP="192.168.2.5"
RECV_MAC="00:13:72:0f:75:cd"

REMOTE_UP=255
REMOTE_TIME=0

HOST=`hostname -s`
zpstatus="/sbin/zpool status -x"

SNAPSHOTS=( "archive" "development" "miscdata" "music" "pictures" "plex" "school" "services")

echo "Creating Daily Snapshot $NEWSNAP"

/sbin/zfs snapshot $SEND@$NEWSNAP
for volume in "${SNAPSHOTS[@]}"; do
  /sbin/zfs snapshot $SEND/$volume@$NEWSNAP
  echo $volume
done

#Check pool status, capture exit code in variable
echo "ZFS AutoBackup utility started on $(date)"
$zpstatus
zpstate=$?

#Send an email alert in the event of any issues with the pool
if [ $zpstate != 0 ] ; then
    echo "Sending Alert Email"
    /sbin/zpool status | mail -s "ZFS POOL ERROR on $HOST" "$EMAIL"
fi

echo "Waking up $RECV_IP $RECV_MAC"

/usr/bin/wakeonlan $RECV_MAC
/usr/bin/wakeonlan $RECV_MAC
/usr/bin/wakeonlan $RECV_MAC

echo "Waiting for $RECV_IP to come online"
while ! [[ "$REMOTE_UP" -eq 0 ]]; do
  ssh -q -o ConnectTimeout=1 $RECV_IP exit
  REMOTE_UP=$?
  REMOTE_TIME=$(expr $REMOTE_TIME + 1)
done
echo "Connected to $RECV_IP after $REMOTE_TIME seconds"


for volume in "${SNAPSHOTS[@]}"; do
  echo "Transferring $volume to $RECV_IP"
  /sbin/zfs send -I $OLDSNAP $SEND/$volume@$NEWSNAP  | pv | ssh $RECV_IP zfs recv $RECV/$volume -F
done

ssh $RECV_IP "/sbin/shutdown now -P"
