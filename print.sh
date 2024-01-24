start_time=$(date +%s%3N)

while true; do
    current_time=$(date +%s%3N)
    
    elapsed_time=$((current_time - start_time))

    if [ $elapsed_time -le 30000 ]; then
        echo "hello ${elapsed_time}ms"
        sleep 0.5
    else 
        break
    fi
done

echo "hello world >>>>>>>>>>>"

exit 0