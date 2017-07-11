#!/bin/bash


pids=""
awk -F',' '{ if(length($21) < 1) {print FILENAME".gz"}}' file*.csv >> list &
pids+=" $!"
awk -F',' '{ if(length($21) < 1) {print FILENAME".gz"}}' file2*.csv >> list &
pids+=" $!"
awk -F',' '{ if(length($21) < 1) {print FILENAME".gz"}}' file3*.csv >> list &
pids+=" $!"

#the wait time will be the max processing time of the pids jobs.
for p in $pids; do
       if wait $p; then
                echo "Process $p success"
        else
                echo "Process $p fail"
          exit 1
        fi
done
