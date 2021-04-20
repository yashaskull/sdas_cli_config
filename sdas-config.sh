calc_wt_size() {
  # NOTE: it's tempting to redirect stderr to /dev/null, so supress error 
  # output from tput. However in this case, tput detects neither stdout or 
  # stderr is a tty and so only gives default 80, 24 values
  WT_HEIGHT=17
  WT_WIDTH=$(tput cols)

  if [ -z "$WT_WIDTH" ] || [ "$WT_WIDTH" -lt 60 ]; then
    WT_WIDTH=80
  fi
  if [ "$WT_WIDTH" -gt 178 ]; then
    WT_WIDTH=120
  fi
  WT_MENU_HEIGHT=$(($WT_HEIGHT-7))
}

do_restart() 
{
    if (whiptail --yesno "Are you sure you want to restart the SDAS ?" 20 60 1); then
        echo "Restarting SDAS" # Will add sudo reboot 
    else
        echo "Not restarting the sdas"
    fi
}

do_shutdown()
{
    if (whiptail --yesno "Are you sure you want to shutdown the SDAS ?" 20 60 1); then
        echo "Shutting down the SDAS" # Will add sudo shutdown now 
    else
        echo "Not shutting down the sdas"
    fi
}

# Performance functions
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

do_cpu_temperature()
{
  #deg_c=$\xe2\x84\x83
  whiptail --title "Seismic Data Acquisition System (SDAS) Coniguration Interface" --msgbox "RPi CPU temperature: Deg C" 10 70
}
do_performance()
{   
    FUN=$(whiptail --title "Seismic Data Acquisition System (SDAS) Coniguration Interface" --menu "Performance Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
        "P1 Memory" "System memory stats" \
        "P2 CPU" "System CPU and memory usage" \
        "P3 Storage" "System storage usage" \
        "P4 Temperature" "CPU temperature" \
        3>&1 1>&2 2>&3)
    RET=$?
    if [$RET -eq 1 ]; then
        return 0
    elif [ $RET -eq 0 ]; then
        case "$FUN" in
            P1\ *) do_memory ;;
            P2\ *) do_cpu ;;
            P3\ *) do_storage_usage ;;
            P4\ *) do_cpu_temperature ;;
            *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
        esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
    fi
}
#
# Interactive use loop
#
calc_wt_size
while true; do
  FUN=$(whiptail --title "Seismic Data Acquisition System (SDAS) Coniguration Interface" --menu "Choose option below:" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Finish --ok-button Select \
    "1 Restart" "Restart the SDAS" \
    "2 Shutdown" "Shutdown the SDAS" \
    "3 Network" "Change networking configuration" \
    "4 Station" "Edit station information" \
    "5 Timing" "View or edit the SDAS timing functionality" \
    "6 Data Storage" "Change how data is stored on the SDAS" \
    "7 Process" "View key processes running on the SDAS" \
    "8 Performance" "View performance parameters of the SDAS" \
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