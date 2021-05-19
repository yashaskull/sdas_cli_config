#!/bin/bashy


calc_wt_size() {
  # NOTE: it's tempting to redirect stderr to /dev/null, so supress error 
  # output from tput. However in this case, tput detects neither stdout or 
  # stderr is a tty and so only gives default 80, 24 values
  WT_HEIGHT=18
  WT_WIDTH=$(tput cols)

  if [ -z "$WT_WIDTH" ] || [ "$WT_WIDTH" -lt 60 ]; then
    WT_WIDTH=80
  fi
  if [ "$WT_WIDTH" -gt 178 ]; then
    WT_WIDTH=120
  fi
  WT_MENU_HEIGHT=$(($WT_HEIGHT-10))
}

# Restart
do_restart() 
{
    if (whiptail --yesno "Are you sure you want to restart the SDAS ?" 20 60 1); then
        echo "Restarting SDAS" # Will add sudo reboot 
    else
        echo "Not restarting the sdas"
    fi
}

# Shutdown
do_shutdown()
{
    if (whiptail --yesno "Are you sure you want to shutdown the SDAS ?" 20 60 1); then
        echo "Shutting down the SDAS" # Will add sudo shutdown now 
    else
        echo "Not shutting down the sdas"
    fi
}

# Network functions
do_network()
{
    while true; do
      FUN=$(whiptail --title "Seismic Data Acquisition System (SDAS) Coniguration Interface" --menu "\nSelect networking option below" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
          "N1 DHCP"   "Automatically configure network as DHCP" \
          "N2 STATIC"   "Manually assign static IP address" \
          "N3 Restart"   "Restart network interface" \
          3>&1 1>&2 2>&3)
      RET=$?
      if [$RET -eq 1 ]; then
          return 0
      elif [ $RET -eq 0 ]; then
          case "$FUN" in
              N1\ *) do_dhcp ;;
              N2\ *) do_static ;;
              N3\ *) do_network_restart ;;
              *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
          esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
      else
        return 0
      fi
  done

}
#do_dhcp()
#{

#}

#do_static()
#{
  
#}

do_network_restart()
{
    # get networking interface names
    array_network_interface=()
    for iface in $(ifconfig | cut -d ' ' -f1| tr ':' '\n' | awk NF)
    do
      array_network_interface+=("$iface")
      array_network_interface+=("")
    done
  
    #array_network_interface+=("All")
    #array_network_interface+=("")
    
    while true; do
        network_interface_choice=$(whiptail --title "Seismic Data Acquisition System (SDAS) Coniguration Interface" --menu "\nSelect network interface to restart" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select  \
            "${array_network_interface[@]}" \
            "All" "Restart all network interfaces" \
            3>&1 1>&2 2>&3)
        RET=$?
        if [$RET -eq 1 ]; then
            return 0
        elif [ $RET -eq 0 ]; then
            # perform restart on interface chosen. Then exit
            echo "Performing network restart on $network_interface_choice"
            ip link set $network_interface_choice down && ip link set $network_interface_choice up 
            #exit 1
        else
          return 0
        fi
    done
}


# System performance functions
do_performance()
{   
  while true; do
      FUN=$(whiptail --title "Seismic Data Acquisition System (SDAS) Coniguration Interface" --menu "\nSelect system performance option below" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
          "P1 Memory" "System memory usage" \
          "P2 CPU" "System CPU and memory usage" \
          "P3 Storage" "System storage usage" \
          "P4 RPi vcgencmd" "View RPi general command service" \
          3>&1 1>&2 2>&3)
      RET=$?
      if [$RET -eq 1 ]; then
          return 0
      elif [ $RET -eq 0 ]; then
          case "$FUN" in
              P1\ *) do_memory ;;
              P2\ *) do_cpu ;;
              P3\ *) do_storage_usage ;;
              P4\ *) do_vcgencmd ;;
              *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
          esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
      else
        return 0
      fi
  done
}
do_memory()
{  
    header=$(free -h | sed -n '1'p)
    mem=$(free -h | sed -n '2'p)
    swap=$(free -h | sed -n '3'p)
    
    whiptail --title "Seismic Data Acquisition System (SDAS) Coniguration Interface" --msgbox "System memory stats\n
    $header 
    $mem
    $swap" 20 90 
}

do_cpu()
{
  header=$(top -b -n 1 | head -n 15)
  
  whiptail --title "Seismic Data Acquisition System (SDAS) Coniguration Interface" --msgbox "System CPU and memory usage\n
  $header" 30 90 
  
}

do_storage_usage()
{
  storage_usage=$(df -h)

  whiptail --title "Seismic Data Acquisition System (SDAS) Coniguration Interface" --msgbox "System storage usage\n
  $storage_usage" 30 90
}

do_vcgencmd()
{
  
  temp=$(vcgencmd measure_temp | sed -r 's/.{5}//')
  cpu_core_voltage=$(vcgencmd measure_volts | sed -r 's/.{5}//')
  sdram_core_voltage=$(vcgencmd measure_volts sdram_c | sed -r 's/.{5}//')
  throttle_state=$(vcgencmd get_throttled | sed -r 's/.{10}//')
  arm_freq=$(vcgencmd measure_clock arm | sed -r 's/.{14}//')
  arm_freq_mhz=$((arm_freq/1000000))
  
  whiptail --title "Seismic Data Acquisition System (SDAS) Coniguration Interface" --msgbox "RPi general command service usage\n
  CPU temperature: $temp\n
  CPU core voltage: $cpu_core_voltage\n
  SDRAM core voltage: $sdram_core_voltage\n
  CPU throttle state: $throttle_state\n
  CPU (arm) clock freq: $arm_freq_mhz"MHz"" 20 70
  
}

#
# Interactive use loop
#
calc_wt_size
while true; do
  FUN=$(whiptail --title "Seismic Data Acquisition System (SDAS) Coniguration Interface" --menu "\nSelect configuration option below" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Finish --ok-button Select \
    "1 Restart" "Restart the SDAS" \
    "2 Shutdown" "Shutdown the SDAS" \
    "3 Network" "Change network configuration" \
    "4 Station" "Edit station information" \
    "5 Timing" "View or edit the SDAS timing functionality" \
    "6 Data Storage" "Change how data is stored on the SDAS" \
    "7 Process" "View key processes running on the SDAS" \
    "8 System performance" "View operating system performance stats" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    do_finish
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      1\ *) do_restart ;;
      2\ *) do_shutdown ;;
      3\ *) do_network ;;
      8\ *) do_performance;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
  else
    exit 1
  fi
done
