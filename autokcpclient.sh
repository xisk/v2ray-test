#!/bin/bash
PORT=26158  #SSH port
TTIINIT=20
UPLINKCAPINIT=1
MAXTTI=20
MAXUPLINK=2

IP=`jq .outbound.settings.vnext[0].address /etc/v2ray/config.json|sed "s/\"//g"` # server address
PROXY=`jq .inbound.protocol /etc/v2ray/config.json|sed "s/\"//g"`
PROXYPORT=`jq .inbound.port /etc/v2ray/config.json`
PROXY=$PROXY://127.0.0.1:$PROXYPORT
DOWNLOAD_LINK="http://www.dvlnx.com/software/gnu/denemo/denemo-2.0.8.tar.gz"

# configure ssh connection reusing
SSHCONFIG="${HOME}/.ssh/config"
if [[  ! -f $SSHCONFIG ]]; then
  echo -e "host *\nControlMaster auto\nControlPath ~/.ssh/master-%r@%h:%p\nControlPersist 1800s"> $SSHCONFIG
elif [[ -z `sed -n "/^ *host/p" $SSHCONFIG` ]]; then #no ezit host *
  sed -i "$ a host \*" $SSHCONFIG
  sed -i "/^ *host/a ControlMaster auto\nControlPath ~/.ssh/master-%r@%h:%p\nControlPersist 1800s" $SSHCONFIG
elif [[ 1 ]]; then
   if [[ -z `sed -n '/^ *ControlMaster/p' $SSHCONFIG` ]]; then
     sed -i "/^ *host/a ControlMaster auto" $SSHCONFIG
   fi
   if [[ -z `sed -n '/^ *ControlPath/p' $SSHCONFIG` ]]; then
     sed -i "/^ *host/a ControlPath ~/.ssh/master-%r@%h:%p" $SSHCONFIG
   fi
   if [[ -z `sed -n '/^ *ControlPersist/p' $SSHCONFIG` ]]; then
     sed -i "/^ *host/a ControlPersist 1800s" $SSHCONFIG
   fi
fi

ssh -MNf -p $PORT root@$IP  2>/dev/null \
    && ssh -p $PORT -t root@$IP "echo "tti uplinkCap serverReceive serverReceive">serverresult.txt" 2>/dev/null
echo -n "Testing..."
echo "filezise speed">clientresult.txt
for (( TTI = $TTIINIT; TTI <= $MAXTTI; TTI++ )); do
  for (( UPLINKCAP = $UPLINKCAPINIT; UPLINKCAP <= $MAXUPLINK; UPLINKCAP++ )); do
    ssh -p $PORT -t root@$IP "bash autokcpserver.sh ${TTI} ${UPLINKCAP}" 2>/dev/null
    curl -x $PROXY -Lo /dev/null -skw "%{size_download} %{speed_download}" $DOWNLOAD_LINK \
        |awk '{printf "%0.2fMB %0.2fMB/s\n",$1/1024/1024,$2/1024/1024}' >> clientresult.txt
    percent=$[((TTI-TTIINIT)*(MAXUPLINK - UPLINKCAPINIT + 1)+ UPLINKCAP - UPLINKCAPINIT +1) * 100 \
    / ((MAXTTI - TTIINIT+1)*(MAXUPLINK- UPLINKCAPINIT + 1))]
    echo -en "\\033[15G $[percent - 1] % completed"
  done
done

ssh -p $PORT -t root@$IP "bash autokcpserver.sh $[TTI-1] $[UPLINKCAP-1]"  2>/dev/null #get the last data
scp -P $PORT root@$IP:~/serverresult.txt ./serverresult.txt >/dev/null
ssh  -p $PORT root@$IP -O exit 2>/dev/null

LINE=`wc -l serverresult.txt | cut -d ' ' -f 1`
for (( i = 2; i < $LINE; i++ )); do
  SERRX0=`awk 'NR=='$i'{print $3}' serverresult.txt`
  SERRX1=`awk 'NR=='$[i+1]'{print $3}' serverresult.txt`
  SERRX=`echo $SERRX0 $SERRX1 |awk '{printf "%0.2fMB",($2-$1)/1024/1024}'`
  SERTX0=`awk 'NR=='$i'{print $4}' serverresult.txt`
  SERTX1=`awk 'NR=='$[i+1]'{print $4}' serverresult.txt`
  SERTX=`echo $SERTX0 $SERTX1 |awk '{printf "%0.2fMB",($2-$1)/1024/1024}'`
  sed -i "s/${SERRX0}/${SERRX}/g" serverresult.txt
  sed -i "s/${SERTX0}/${SERTX}/g" serverresult.txt
done
sed -i '$d' serverresult.txt
paste serverresult.txt clientresult.txt > result.txt
rm serverresult.txt clientresult.txt
echo -e "\nThe test is completed."
printf '%5s %10s %15s %15s %15s %15s \n' $(cat result.txt)
RESPATH=`pwd`
echo "Test result is saved to ${RESPATH}/result.txt"
exit 0
