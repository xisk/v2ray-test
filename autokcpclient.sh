#!/bin/bash
PORT=2222  #SSH port
IP=1.2.3.4 # server address

TTIINIT=20
UPLINKCAPINIT=1
MAXTTI=21
MAXUPLINK=3

echo -n "Testing ..."
ssh -p $PORT -t root@$IP "echo "tti:upLink:serverRx:serverTx">serverresult.txt" 2>/dev/null
echo "filezise:speed">clinetresult.txt
for (( TTI = $TTIINIT; TTI <= $MAXTTI; TTI++ )); do
  for (( UPLINKCAP = $UPLINKCAPINIT; UPLINKCAP <= $MAXUPLINK; UPLINKCAP++ )); do
    ssh -p $PORT -t root@$IP "bash autokcpserver.sh ${TTI} ${UPLINKCAP}"
    proxychains wget -background http://www.dvlnx.com/software/gnu/denemo/denemo-2.0.8.tar.gz >/dev/null #16MB
    #proxychains wget -background http://www.dvlnx.com/software/gnu/gawk/gawk-3.0.6.tar.gz >/dev/null  #1MB
    SPEED=`grep B/s ckground`
    while  [[ -z $SPEED ]]; do
      SPEED=`grep B/s ckground`
    done
    FILESIZE=`grep B/s ckground |cut -d '[' -f 2|cut -d '/' -f 1`
    FILESIZE=`expr $FILESIZE / 1000000`
    echo "${FILESIZE}MB:`grep B/s ckground |cut -d '(' -f 2|cut -d ')' -f 1`">>clinetresult.txt
    rm denemo-2.0.8.tar.gz
    #rm gawk-3.0.6.tar.gz
    rm ckground
    percent=$[$[$[$[$[TTI-TTIINIT] * $[MAXUPLINK - UPLINKCAPINIT + 1]] + $[UPLINKCAP - UPLINKCAPINIT + 1]] * 100] \
        / $[$[MAXTTI - TTIINIT + 1] * $[MAXUPLINK - UPLINKCAPINIT + 1]]]
    echo -en "\\033[25G $[percent - 1] % completed"
  done
done

ssh -p $PORT -t root@$IP "bash autokcpserver.sh $[TTI-1] $[UPLINKCAP-1]" 2>/dev/null #get the last data
scp -P $PORT root@$IP:~/serverresult.txt ./serverresult.txt >/dev/null
cp serverresult.txt serverresult.txt.bak
LINE=`wc -l serverresult.txt | cut -d ' ' -f 1`
echo "tti:uplinkCap:serverRx:serverTx:filezise:speed" > result.txt
for (( i = 2; i < $LINE; i++ )); do
  SERRX0=`head -n $i serverresult.txt |tail -n 1|cut -d ':' -f 3`
  SERRX1=`head -n $[i+1] serverresult.txt |tail -n 1|cut -d ':' -f 3`
  SERRX=`expr $SERRX1 - $SERRX0`
  SERRX=`expr $SERRX / 1000000`
  SERTX0=`head -n $i serverresult.txt |tail -n 1|cut -d ':' -f 4`
  SERTX1=`head -n $[i+1] serverresult.txt |tail -n 1|cut -d ':' -f 4`
  SERTX=`expr $SERTX1 - $SERTX0`
  SERTX=`expr $SERTX / 1000000`
  sed -i "s/${SERRX0}/${SERRX}MB/g" serverresult.txt
  sed -i "s/${SERTX0}/${SERTX}MB/g" serverresult.txt
  CLIENTRES=`head -n $i clinetresult.txt |tail -n 1`
  SERVERRES=`head -n $i serverresult.txt |tail -n 1`
  echo "${SERVERRES}:${CLIENTRES}" >> result.txt
done
rm serverresult.txt clinetresult.txt
sed -i "s/ //g" result.txt
sed -i "s/:/ /g" result.txt
echo -e "\nThe test is completed."
printf '%5s %10s %10s %10s %10s %12s \n' $(cat result.txt)
RESPATH=`pwd`
echo "Test result is saved to ${RESPATH}/result.txt"
exit 0
