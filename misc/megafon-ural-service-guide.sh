#!/usr/bin/env bash
# Description: Get balance info from Megafon Service Guide.

export PATH="/bin:/usr/bin:/usr/local/bin"

print_usage() {
local red='\e[0;31m'; NC='\e[0m'
echo -e "${red}Please register and get a password to the Megafon Service Guide at https://uralsg.megafon.ru/.
After registration unblock robot in Service Guide Settings.${NC}

Usage:
  ${0##*/} [options] [phone_number] [password]
 List of possible options:
  --raw		print raw response from Service Guide,
  --balance	print account balance (for monitoring purposes),
  --traffic	print traffic information,
  --full	print account, balance, traffic info,
  --usage	print this help.
 phone_number	10-digits phone number (without country code).
 password	Service Guide password."
exit 0
}

PARAM=$1
shift 1

login=$1
password=$2

response=$(curl -sk "https://uralsg.megafon.ru/ROBOTS/SC_TRAY_INFO?X_Username=$login&X_Password=$password")
name=$(echo "$response" |grep "<NAME>" |head -n 1 |grep -oE ">.*<" |tr -d \<\>)
number=$(echo "$response" |grep "<NUMBER>" |head -n 1 |grep -oE ">.*<" |tr -d \<\>)
status=$(echo "$response" |grep "<STATUS>" |head -n 1 |grep -oE ">.*<" |tr -d \<\>)
balance=$(echo "$response" |grep "<BALANCE>" |head -n 1 |grep -oE ">.*<" |tr -d \<\>)
plan=$(echo "$response" |grep "<PLAN_NAME>" |head -n 1 |grep -oE ">.*<" |tr -d \<\>)
vTotal=$(echo "$response" |grep "<VOLUME_TOTAL>" |head -n 1 |grep -oE ">.*<" |tr -d \<\>)
vAvailable=$(echo "$response" |grep "<VOLUME_AVAILABLE>" |head -n 1 |grep -oE ">.*<" |tr -d \<\> |cut -d. -f1)
vUsed=$(echo $(($vTotal - $vAvailable)))

case $PARAM in
--full )
echo "$name (phone: $number status: $status)
Plan: $plan, Total: $vTotal MB, Used: $vUsed MB, Available: $vAvailable MB.
Balance: $balance RUR"
;;
--balance ) echo $balance ;;
--traffic ) echo "Total: $vTotal kB, Used: $vUsed kB, Available: $vAvailable kB" ;;
--raw ) echo "$response" ;;
--usage|--help|-h|* ) print_usage ;;
esac
