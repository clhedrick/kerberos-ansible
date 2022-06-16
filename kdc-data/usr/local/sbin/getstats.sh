#!/bin/bash
# get stats for Linux machine for nagios and pnp4nagios
#by Hanz Makmur 12-10-2015

lscpu=`which lscpu`
CPUcount=`$lscpu | grep '^CPU(s)' | awk '{print $2}'`
LIMIT1=";"$((CPUcount * 3 ))";"$(( CPUcount * 5 ))
#
LIMIT2=";5000;8000"
LIMIT3=";"$((CPUcount * 4 ))";"$(( CPUcount * 5 ))
#------------
touch=`which touch`
df=`which df`
netstat=`which netstat`
grep=`which grep`
pgrep=`which pgrep`
wc=`which wc`
uptime=`which uptime`
awk=`which gawk`;
tr=`which tr`
free=`which free`
timeout=`which timeout`
ps=`which ps`
ps="$timeout -k 3 6 $ps"
w=`which w`
netstat=`which netstat`
sed=`which sed`
iostat=`which iostat`
cut=`which cut`
tr=`which tr`
tail=`which tail`
cat=`which cat`
lsof=`which lsof`
nvidia="/usr/bin/nvidia-smi"
myname=`hostname`
label=''
#
#format needed: 'label'=value[UOM];[warn];[crit];[min];[max]
#
UPTIME=" `$uptime|$awk 'BEGIN {FS=","}{print $1}'`"
LOAD="Load="`$cat /proc/loadavg | awk {'print $2'}`
sshcount=`$ps -ef | $grep -c -e "[s]shd: .*pts"`
x2gocount=`$ps -e | $grep -c "[x]2goagent"`
xrdpcount=`$ps -e | $grep -c "[x]rdp-chansrv"`
jupyterhubcount=`$ps -ef | $grep -c "[j]upyterhub-singleuser"`
zeppelincount=`comm -2 -3  <(ps  -ef --no-headers |grep [z]eppelin |awk '{print $1}' | sort -u) <(awk 'BEGIN{FS=":";}{print $1}' /etc/passwd |sort -u)|wc -l`

#
LOCALLOGIN=`$w | grep -c -E ":[0-9] "`
SSH="SSH=$sshcount"
X2GO="x2go=$x2gocount"
XRDP="XRDP=$xrdpcount"
JUPYTERHUB="JupyterHub=$jupyterhubcount"
ZEPPELIN="Zeppelin=$zeppelincount"
#
LOGINS="Logins="$((sshcount + x2gocount + LOCALLOGIN + xrdpcount + jupyterhubcount + zeppelincount))
PROCS="Processes="`$ps -ae|$grep -v nobody|$wc -l`
CONNECT="Connections="`$netstat -s | $grep -i 'connections established' | $awk '{print $1}'`
FREEMEM="FreeMem=`$free -m|$awk '{if ($1 == "Mem:") print $4;}'`MB"
BUFFER="Buffer=`$free -m|$awk '{if ($1 == "Mem:") print $6;}'`MB"
#
MAXMEM=`$free -m|$awk '{if ($1 == "Mem:") { printf "%d", $2 }}'`
LOWMEMLIMIT=7000
HIGHMEMLIMIT=10000
#
USEDMEM="UsedMem=`$free -m|$awk '{if ($1 == "Mem:") print $3;}'`MB;$LOWMEMLIMIT;$HIGHMEMLIMIT"
#
MAXSWAP=`$free -m|$awk '{if ($1 == "Swap:") { printf "%d", $2 }}'`
LOWSWAPLIMIT=$((MAXSWAP * 2 / 3 ))
HIGHSWAPLIMIT=$((MAXSWAP * 5 / 6 ))
#
USEDSWAP="UsedSwap=`$free -m|$awk '{if ($1 == "Swap:") print $3;}'`MB;$LOWSWAPLIMIT;$HIGHSWAPLIMIT"
OPENFILE="OpenFileHandles=`$awk '{print $1";150000;"$3}' /proc/sys/fs/file-nr`"
INCOMING="`$netstat -s |$grep InOctets|$sed 's/: /=/g'`"
OUTGOING="`$netstat -s |$grep OutOctets|$sed 's/: /=/g'`"
VARDISK="VarDisk=`$timeout -k 5 10 $df -P /var/log | $awk '{if ($1 != "Filesystem"){print $5}}'`"
ROOTDISK="RootDisk=`$timeout -k 5 10 $df -P / | $awk '{if ($1 != "Filesystem"){print $5}}'`"

GPUDISK="`$timeout -k 5 10 $df -P /gpu 2>/dev/null | $awk '{if ($0 == "" ) {exit;} ;if ($1 != "Filesystem"){print $5}}'`"
GPU2DISK="`$timeout -k 5 10 $df -P /gpu2 2>/dev/null  | $awk '{if ($0 == "" ) {exit;} ;if ($1 != "Filesystem"){print $5}}'`"

#
if [ -f $nvidia ];then
  GPU_INFO=`$timeout -k 3 6  $nvidia -q | egrep 'GPU Current Temp|Fan' | sed 's/ //g' |  sed 's/:/ /' |  sed 's/N\/A/0/'| \
  $awk ' BEGIN {fanspeed=0;temp=0;} { \
 if ($1 ~ /Fan/) { if ($2 > fanspeed) { fanspeed=$2;}} \
 if ($1 ~ /Temp/) { if($2 > temp) {temp=$2;}} \
} END { printf "%s=%s %s=%s\n", "GPUFanSpeed", fanspeed, "GPUCurrentTemp", temp;}'`
#
 GPU_APP=`$timeout -k 3 6  $nvidia pmon -s u -c 1 | awk 'BEGIN {count=0;}{if ($1 ~/^[0-9]+/ && $2 ~/^[0-9]+/  && $3 ~/^C/ ){count++;} } END{print "ActiveGPUApps="count}'`
 GPU_Load=`$timeout -k 3 6 $nvidia  --query-gpu=utilization.gpu --format=csv,noheader,nounits | awk '{load+=$1; count++} END {print "GPU_Load=" load / count"%"}'`
 GPU_Mem_Used=`$timeout -k 3 6 $nvidia --query-gpu=utilization.memory --format=csv,noheader,nounits | awk '{mem+=$1; count++} END {print "GPU_Mem_Used=" mem / count"%"}'`
else 
  GPU_INFO="GPUFanSpeed=0  GPUCurrentTemp=0C "
  GPU_APP="ActiveGPUApps=0 "
  GPU_Load="GPU_Load=0%"
  GPU_Mem_Used="GPU_Mem_Used=0%"
fi

$touch /tmp/write_test
READONLY="READONLY="$?

#$HD_TEMP="HD_Temp=`/sbin/hddtemp -uF -n /dev/sda`"
#
CPU_REPORT=`$iostat -c | $tr -s ' ' ';' | $sed '/^$/d' | $tail -1`
CPU_USER=`echo $CPU_REPORT | $cut -d ";" -f 2`"%"
CPU_SYSTEM=`echo $CPU_REPORT | $cut -d ";" -f 4`"%"
CPU_IOWAIT=`echo $CPU_REPORT | $cut -d ";" -f 5`"%"
CPU_IDLE=`echo $CPU_REPORT | $cut -d ";" -f 7`"%"
if [ -f /usr/bin/sensors ]
then
CPU_TEMP=`/usr/bin/sensors -f -A 2>/dev/null |  awk 'BEGIN {FS=":"; cpu=0;} { if ($1 ~ /Package|CPU|Physical/) { linecount++; $line=gensub(/\)| |F|\(|\053|\260|\302|(high)|,|(crit)/,"","g",$2);  $line=gensub(/=/," ","g",$line);  split ($line, a, " " ); if (linecount>1){count=linecount}else{count=""}  if ( a[1] != a[2] ) {warn=int(a[2]+4); crit=int(a[3]); cpu=a[1]; printf "CPU"count"_Temp="a[1]";"warn";"crit" ";}}}END{if (cpu == 0){print "CPU_Temp=0"}}'`

else
  CPU_TEMP="CPU_Temp=0"
fi

#exception host
if [ $myname = "jupyter.cs.rutgers.edu" ] || [ $myname = "data8.cs.rutgers.edu" ]; then
  MSG=$JUPYTERHUB
else
   if [ $myname = "data-services2.cs.rutgers.edu" ] ||  [ $myname = "data7.cs.rutgers.edu" ]; then
     MSG=$ZEPPELIN
   else
    MSG=$XRDP
   fi
fi


if [ $myname = "amarel.cs.rutgers.edu" ]; then  
   VM="TotalVM=`ps -aef | grep -e "[qe]mu-system-x86_64" | grep -vc nobody`"
fi


if [ $myname = "irv.cs.rutgers.edu" ]; then  
   IRVM="TotalVM=`ps -aef | grep -e "[qe]mu-system-x86_64" | grep -vc nobody`"
fi

LICENSECOUNT=""          
if [ -f /usr/local/sbin/licensemanager.sh ]; then 
  LICENSECOUNT=$(/usr/local/sbin/licensemanager.sh)                             
fi                                    
                                          
#special service watch for amabari
if [ $myname = "data-services1.cs.rutgers.edu" ] || [ $myname = "data-services5.cs.rutgers.edu" ]; then
   if [ -f /var/tmp/ambari-status.counts ]; then
      HADOOPISSUE=`sed 's/\r//' /var/tmp/ambari-status.counts`
   fi
fi

if [ ! -z ${GPUDISK} ]; then
  GDISK="GPUDISK=${GPUDISK};95;99"
fi

if [ ! -z ${GPU2DISK} ]; then
   GDISK="${GDISK} GPU2DISK=${GPU2DISK};95;99 "
fi


echo -n "$label \
${SSH} \
${X2GO} \
${MSG} \
${LOAD} \
${UPTIME} \
| \
${SSH}${LIMIT3} \
${X2GO}${LIMIT3} \
${LOGINS}${LIMIT3} ${VM} \
${CONNECT}${LIMIT2} \
${LOAD}${LIMIT1} \
${PROCS} \
${OPENFILE} \
${FREEMEM} \
${BUFFER} \
${USEDSWAP} \
${INCOMING} \
${OUTGOING} \
User_Cpu=${CPU_USER} \
System_Cpu=${CPU_SYSTEM} \
IOWait=${CPU_IOWAIT} \
Idle=${CPU_IDLE} \
${VARDISK};88;93 \
${ROOTDISK};88;93 \
${GDISK} \
${READONLY};1;1 \
${GPU_INFO} \
${CPU_TEMP} \
${GPU_APP} \
${MSG}${LIMIT3} \
${LICENSECOUNT} \
${HADOOPISSUE} \
${USEDMEM} ${IRVM} \
${GPU_Load} ${GPU_Mem_Used}
"
#
