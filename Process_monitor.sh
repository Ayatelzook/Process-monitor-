#!/usr/bin/bash


function List-Process () {
    echo "--------------------------listing-----------------------------------"
    echo " "
    ps aux  ##list all running processes
    ps -A
    echo " "
    echo "---------------------------------------------------------------------"
    Interactive_Mode
}

function Process_Info () {
    
    echo "--------------------------Process information-----------------------------------"
    echo " "
    echo "Enter PID :"
    read -r pid
    echo "PID :$pid"    
    processName=$(ps -p $pid -o comm=)
    echo "process name :$processName"
    Parent_PID=$(ps -o ppid= -p $pid)
    echo "PPID :$Parent_PID"
    user=$(ps -o user= -p $pid)
    echo "User :$user"
    cpu=$(ps -o %cpu= -p $pid)
    echo "CPU :$cpu"
    Memory=$(ps -o %mem= -p $pid)
    echo "Mem :$Memory"
    stat=$(ps -o stat= -p $pid)
    echo "STAT :$stat"
    time=$(ps -o time= -p $pid)
    echo "TIME :$time"
    echo " "
    echo "--------------------------------------------------------------------------------"
    Interactive_Mode
}

function kill_process () {
   
    echo "-----------------------------------kill-----------------------------------"
    echo " "
    echo "Enter PID :"
    read -r pid
    kill -TERM $pid
    echo " "
    echo "--------------------------------------------------------------------------"
    Interactive_Mode
}

function Process_Statistics () {

    echo "--------------------------Process Statistics---------------------------------"
    echo " "
    total_num_processes=$(ps -e | wc -l)                   
    echo "Total Number of processes :$total_num_processes"
    used_memory=$(free -m | awk '/Mem:/ {print $3}')
    echo "used_memory :$used_memory" 
    cpu_load=$(ps -eo %cpu | awk '{s+=$1} END {print s "%"}')
    echo "cpu load average :$cpu_load" 
    echo " "
    echo "------------------------------------------------------------------------------"
    Interactive_Mode
}

function Real_time_monitoring() {

    clear
    echo "---------------------------Real-time Process Monitoring------------------------"
    echo " "

    # Get total number of processes
    total_processes=$(ps -e | wc -l)

    # Get memory usage
    memory_usage=$(free -m | awk '/Mem:/ {printf "%.2f GB\n", $3/1000.0}')

    # Get CPU load
    cpu_load=$(ps -eo %cpu | awk '{s+=$1} END {printf "%.2f%%\n", s}')

    echo "Total Processes: $total_processes"
    echo "Memory Usage: $memory_usage"
    echo "CPU Load: $cpu_load"

    # Display the running processes sorted by CPU usage
    echo "Top Processes by CPU Usage:"
    echo "PID  USER       CPU%  COMMAND"
    ps -eo pid,user,%cpu,comm --sort=-%cpu | head -n 6 | awk '{printf "%-5s %-10s %-6s %s\n", $1, $2, $3, $4}'
    echo " "
    echo "Switching to interactive terminal. Press Ctrl+C to return to monitoring."
    echo " "
}

function switch_to_terminal() {
   
    Interactive_Mode
    exec bash
}

function Search () {

    echo "--------------------------Search-----------------------------------"
    echo " "
    echo -n "{{Enter search term }}"
    read -r "search_term" 
    echo "$search_term" 
    echo  "    pid user     %cpu %mem cmd"
    ps -eo pid,user,%cpu,%mem,cmd  | grep -i "$search_term" 
    echo " "
    echo "-------------------------------------------------------------------"
    Interactive_Mode

}

function Interactive_Mode() {

    echo "--------------------------Interactive Mode-----------------------------------"
    echo " "
    echo "Please select an operation:"
    echo "1. List all running processes ."
    echo "2. process information ."
    echo "3. kill process ."
    echo "4. process statistics ."
    echo "5. Real time monitoring ."
    echo "6. Search ."
    echo "7. Resource_Usage_Alert ."
    echo "8. update_configuration ."
    echo "9. display_configuration ."
    echo "10.exit"
    read -r input 
    case "${input}" in
        1)
            List-Process
        ;;
        2)
            Process_Info
        ;;
        3)
            kill_process
        ;;
        4)
            Process_Statistics
        ;;
        5)
            Real_time
        ;;
        6)
            Search
        ;;
        7)
            Resource_Usage_Alert &
        ;;
        8)
            update_configuration
        ;;
        9)
            display_configuration
        ;;
        10)
            Resource_Usage_Alert_pid2=$!
            echo "$Resource_Usage_Alert_pid2"
            kill -TERM $Resource_Usage_Alert_pid2
            exit 0
        ;;
        *)
            echo "default (none of above)"
        ;;
    esac
    echo " "
    echo "----------------------------------------------------------------------------"
}

#Set up alerts for processes exceeding predefined resource usage thresholds.
function Resource_Usage_Alert () {
    
    # Set resource usage thresholds
    cpu_threshold=5  # CPU usage threshold in percentage
    mem_threshold=70  # Memory usage threshold in percentage

    while true; do
        # Get system resource usage
        cpu_usage=$(ps -eo %cpu | awk '{s+=$1} END {printf "%.2f", s}')
        mem_usage=$(free | awk '/Mem:/ {printf "%.2f", $3/$2*100}')

        # Check for resource usage alerts
        if (( $(echo "$cpu_usage > $cpu_threshold" | bc -l) )); then
            echo " "
            echo "CPU usage alert: Current CPU usage is $cpu_usage%, which exceeds the threshold of $cpu_threshold%."
        fi

        if (( $(echo "$mem_usage > $mem_threshold" | bc -l) )); then
            echo "Memory usage alert: Current memory usage is $mem_usage%, which exceeds the threshold of $mem_threshold%."
            echo " "
        fi

        # Wait for the next check interval
        sleep 60 
    done
}

#configuration

CONFIG_FILE="process_monitor.conf"

# Default configuration values
UPDATE_INTERVAL=5
CPU_ALERT_THRESHOLD=90
MEMORY_ALERT_THRESHOLD=80

# Load configuration from file
if [ -f "$CONFIG_FILE" ]; then
  source "$CONFIG_FILE"
else
  echo "Configuration file '$CONFIG_FILE' not found. Using default values."
fi

# Function to save configuration
function save_configuration() {

    cat << EOF > "$CONFIG_FILE"
# Sample configuration file for Process Monitor

# Update interval in seconds
UPDATE_INTERVAL=$UPDATE_INTERVAL

# CPU usage threshold for alerts (percentage)
CPU_ALERT_THRESHOLD=$CPU_ALERT_THRESHOLD

# Memory usage threshold for alerts (percentage)
MEMORY_ALERT_THRESHOLD=$MEMORY_ALERT_THRESHOLD
EOF

  echo "Configuration saved to '$CONFIG_FILE'."
  Interactive_Mode
}

# Function to display the current configuration
function display_configuration() {

    echo "-----------------------------Current Configuration-------------------------------"
    echo " "
    echo "Update Interval: $UPDATE_INTERVAL seconds"
    echo "CPU Alert Threshold: $CPU_ALERT_THRESHOLD%"
    echo "Memory Alert Threshold: $MEMORY_ALERT_THRESHOLD%"
    echo " "
    echo "----------------------------------------------------------------------------------"
    Interactive_Mode

}

# Prompt the user to update the configuration
function update_configuration() {

    echo "-------------------------------Update Configuration---------------------- "
    echo " "
    read -p "Enter new update interval (current: $UPDATE_INTERVAL): " new_update_interval
    if [ -n "$new_update_interval" ]; then
        UPDATE_INTERVAL=$new_update_interval
    fi

    read -p "Enter new CPU alert threshold (current: $CPU_ALERT_THRESHOLD%): " new_cpu_alert_threshold
    if [ -n "$new_cpu_alert_threshold" ]; then
        CPU_ALERT_THRESHOLD=$new_cpu_alert_threshold
    fi

    read -p "Enter new memory alert threshold (current: $MEMORY_ALERT_THRESHOLD%): " new_memory_alert_threshold
    if [ -n "$new_memory_alert_threshold" ]; then
        MEMORY_ALERT_THRESHOLD=$new_memory_alert_threshold
    fi

        echo " "
        echo "---------------------------------------------------------------------------"
    save_configuration
}


function Real_time () {

    while true; do
        update_interval=10
        Real_time_monitoring
        sleep $update_interval
    done
}

function main () {

    Resource_Usage_Alert &
    Resource_Usage_Alert_pid=$!
    echo "$Resource_Usage_Alert_pid"
 
    trap switch_to_terminal SIGINT     ##When the script runs, the trap command sets up a listener for the SIGINT signal.
    Interactive_Mode
}

main