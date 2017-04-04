#!/bin/bash

#Count rows of files.
#-print0  print the full file name on the standard output, followed by a null character
#xargs -0 Input  items  are  terminated by a null character instead of by whitespace


find . -type f -name "*file.log*" -print0 | xargs -0 wc -l

#Dummy Way
#grep to count all line termination 
grep --regexp="$" --count file.log

#Simple way for one file
wc -l file.log | awk '{print $1}'
cat file.log | wc -l
wc -l < file.log