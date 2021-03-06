#!/bin/bash

while IFS=" " read -r server username password;do
timeout 3 ssh -q -n -o BatchMode=yes $username@$server 'exit 66' 
#timout returns code 124 and BatchMode=yes if not with key 255
if [ $? -eq 66 ] ;then
echo "Key exist on $server"
else
./my.exp $server $username $password
fi

done < input_file.txt
