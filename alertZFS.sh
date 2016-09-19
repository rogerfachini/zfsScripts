zpstate=$(/sbin/zpool status | egrep -i '(DEGRADED|FAULTED|OFFLINE|UNAVAIL|REMOVED|FAIL|DESTROYED|corrupt|cannot|unrecover)')

echo $zpstate
#Send an email alert in the event of any issues with the pool
if [  "${zpstate}" ] ; then
    beep -l 4000 -f 2500 -d 3000;
    for i in {1..30};do
      zpstate=$(/sbin/zpool status | egrep -i '(DEGRADED|FAULTED|OFFLINE|UNAVAIL|REMOVED|FAIL|DESTROYED|corrupt|cannot|unrecover)')
      if [  ! "${zpstate}" ] ; then
          beep -l 200  f 500;
          beep -l 200 -f 750;
          beep -l 200 -f 1000;
          beep -l 200 -f 1250;
          break
      fi
      beep -l 200 -d 200 -f 1000;
      beep -l 200 -d 200 -f 750;
      beep -l 200 -d 200 -f 750;
      beep -l 200 -d 200 -f 750;
      sleep 1
    done

fi



