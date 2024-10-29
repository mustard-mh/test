#!/bin/bash

trap '' SIGHUP   
trap '' SIGINT   
trap '' SIGQUIT  
trap '' SIGILL   
trap '' SIGABRT  
trap '' SIGFPE   
trap '' SIGUSR1  
trap '' SIGUSR2  
trap '' SIGALRM  
trap '' SIGTERM  
trap '' SIGCONT  
trap '' SIGTSTP  
trap '' SIGTTIN  
trap '' SIGTTOU  

echo "PID: $$"

while true; do
    echo "running..."
    sleep 5
done