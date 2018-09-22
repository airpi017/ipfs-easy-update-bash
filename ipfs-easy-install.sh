#!/bin/bash
#
# Easy install script for ipfs
# 
# Tue 28th august 2018
#
# Written to make ipfs install easier
# and get into development faster
#
# Send any feedback to: philiptwayne at yahoo com au
# No guarantee of reply or action :)
#
# Enjoy !
#
# 0. Detect UID and sudo with original user account if UID > 0
# 1. Select OS 
# 2. Select CPU instruction set
# 3. Download trickle and specifc IPFS update .gz file for your system
# 4. Run ipfs-update and get available versions
# 5. Run ipfs-update and install latest version
# 6. Initialise ipfs
# 7. Show ipfs readme and then the quick-start pages
# 8. Change permissions to the original user account
# 9. Show WebUI page
#
function show_options() {

 local option=1
 local op_in=$1

 for op_name in ${options[@]}
 do
  if [ $option -le $limit ]; then
   echo " $option) $op_name"
   option=$((option + 1))
  fi
 done

 echo
 read -er -p "Please select $type number: " $op_in
}

function usage() {

 echo "Usage: $0 unpack_dir"
 echo "Under $(pwd) e.g. ./ipfs-dl"
 exit 2
}

#
# Check for usage 
#
[[ $# -eq 0 ]] && usage
unpack_dir=$1

#
# 0. UID detection
#
logname=$USER
# Detect if we used sudo for this instance of the script
[[ $# -eq 2 ]] && logname=$2

if [ "$EUID" -ne 0 ]; then 
  sudo $0 $unpack_dir $logname
  exit 0
fi

#
declare -a os_options=("darwin" "freebsd" "linux" "windows")
#
# 1. OS Selection
#
echo
echo "## Operating systems:"
os=''
type="OS"
limit=4
options=${os_options[@]}

show_options selection 

if [ $selection -ge 1 ]; then
 if [ $selection -le $limit ]; then
   os=${os_options[$(($selection - 1))]}
 else
   echo "## Please start again and select an OS less than 4"
   exit 1
 fi
else
   echo "## Please start again and select an OS less than 4"
   exit 1
fi
#
# 2. CPU instruction set Selection
#
declare -a cpu_set=("2" "3" "3" "2")
declare -a cpu_names=("x86-32bit" "amd-64bit" "arm")
declare -a cpu_id=("386" "amd64" "arm")
#
echo
echo Selected OS $os
echo
echo "## CPU Instruction Sets:"
cpu_set=''
type="$os CPU instruction set"
limit=${cpu_set[$(($selection - 1))]}
options=${cpu_names[@]}

show_options selection

if [ $selection -ge 1 ];then
 if [ $selection -le $limit ];then
  cpu_set=${cpu_id[$(($selection - 1))]}
 else
   echo "## Please start again and select a CPU set for $os between 1 and $limit"
   exit 2
 fi
else
  echo "## Please start again and select a CPU set for $os between 1 and $limit"
  exit 2
fi
echo Selected CPU instruction set $cpu_set
#
# 3. Download trickle for bandwidth management and specifc .gz file
#

# Test for trickle existence
echo
echo "## Checking for trickle used for shaping monthly download speed"
if [[  -z $(which trickle) ]]; then
  trickle_get=$(apt-get install trickle)
  trickle_get=$(which trickle) 
  trickle_installed=$?
  echo "## trickle installed :$trickle_installed"
else
  trickle_installed=0
  echo "## trickle found ok: $trickle_installed"
fi

ipfs_update_url="https://dist.ipfs.io/ipfs-update/v1.5.2"
ipfs_update_gz="ipfs-update_v1.5.2_$os-$cpu_set.tar.gz"
#
mkdir -p $(pwd)/$unpack_dir
cd $(pwd)/$unpack_dir

if [ ! -f $ipfs_update_gz ]; then
 echo
 echo "## Downloading $ipfs_update_gz to $(pwd) ..."
 wget "$ipfs_update_url/$ipfs_update_gz" -q --show-progress
 tar xzf $ipfs_update_gz
else
 echo
 echo "## $ipfs_update_gz exists in $(pwd) ..."
fi
#
# 4. Run ipfs-update and get available versions
#
cd ./ipfs-update
echo "## Getting available versions of ipfs ..."
./ipfs-update versions > ./versions.list
version=$(tail -n1 < ./versions.list)
#
# 5. Run ipfs-update and install latest version
#
echo
echo "## Getting and installing ipfs version $version ..."
./ipfs-update --verbose install $version
#
# 6. Initialise ipfs
#
# Append the ipfs daemon configuration to ~/.profile using IPFS_REPO to seed
#
echo
echo "## FYI - default bandwidth for the IPFS has no throttling policy applied."

trickle_config=

if [[ $trickle_installed -eq 0 ]]; then
  link="0.6" # Default to 3.2GB per month
  echo "For maintaining your internet experience, ~30\% or less of your uplink speed is recommended."
  echo   e.g. 1Mbps uplink speed and 100,000MB per month is about 300kbit/s or 38KBytes/s up+down link speed. 
  echo
  echo "## This install will shape bandwidth around the level you like using 'trickle'"
  echo   "Each   3,200MB per month requires a link speed of about 0.5KB/s (  4kbit/s) for each direction 'up/down'"
  echo   "Each  10,000MB per month requires a link speed of about 1.8KB/s ( 15kbit/s) for each direction 'up/down'"
  echo   "Each 100,000MB per month requires a link speed of about 18 KB/s (145kbit/s) for each direction 'up/down'"
  echo
  read -er -p "## What link speed would you like to contribute to the IPFS [ $link ] KB : " link_in
  [[ $link_in != "" ]] && link=$(echo "scale=1; $link_in / 1" | bc)
  gbpm=$(echo "scale=3; (5263 * $link) / 1" | bc)
  trickle_config="trickle -d $link -u $link"
  echo "## Using "$link"KB/s for each 'up/down' link for ~"$gbpm"MB per month - shaping only, so be vigilant :)"
  read -p "## Hit any key to continue ..."
fi
test_profile_has_ipfs=$(cat ~/.profile | grep ipfs)
if [[ -z $test_profile_has_ipfs && $trickle_installed -eq 0  ]]; then
echo 
echo "## Appending ipfs daemon instructions to ~/.profile for next time :)"
echo '
# Setup ipfs  
IPFS_REPO=~/.ipfs
mkdir -p $IPFS_REPO  
export IPFS_PATH=$IPFS_REPO  
# Detect whether ipfs daemon is missing and start it  
# grep ipfs returns empty string when missing
test_ipfs=$(ps -elf|grep -v grep|grep ipfs) 
[[ -z $test_ipfs ]] && '$trickle_config' ipfs daemon > /dev/null 2>&1 & 
' >> ~/.profile 
else
# Replace trickle config in ~/.profile
echo 
echo "## Modifying link shaping instructions for next time to $trickle_config"
sed -i "s/trickle.* i/$trickle_config i/" ~/.profile
fi

echo
echo "## Initialising ipfs version $version ..."
echo

test_ipfs=$(ps -elf|grep -v grep|grep ipfs)
[[ -z $test_ipfs ]] && $trickle_config ipfs daemon --init > /dev/null 2>&1 & 

echo "## Your (Peer)ID and Public Key can be found using: ipfs id"
peer_id=$(ipfs id|grep ID)
peer_id=$(echo $peer_id|cut -d'"' -f4)
echo "PeerID: $peer_id"
echo
echo "## Welcome to ipfs info: ipfs cat /ipfs/QmS4ustL54uo8FzR9455qaxZwuMiUhyvMcX9Ba8nUH4uVv/readme"
echo "## Capability overview:  ipfs cat /ipfs/QmS4ustL54uo8FzR9455qaxZwuMiUhyvMcX9Ba8nUH4uVv/quick-start|less"
echo

read -e -p "Hit enter to show the readme page ..." 
#
ipfs cat /ipfs/QmS4ustL54uo8FzR9455qaxZwuMiUhyvMcX9Ba8nUH4uVv/readme
echo
read -e -p "## Hit enter to 'less' the quick-start page (q returns you to the prompt) ..." 
ipfs cat /ipfs/QmS4ustL54uo8FzR9455qaxZwuMiUhyvMcX9Ba8nUH4uVv/quick-start|less
#
# 8. Change permissions to suit original user
#
echo
echo "## Changing IPFS permissions to $logname ..."
echo
chown -R $logname ~/.ipfs
chgrp -R $logname ~/.ipfs
echo
echo "## Launching the WebUI for the IPFS ..."
echo
read -e -p "## Hit enter to continue ..." 
x-www-browser http://localhost:5001/webui 
