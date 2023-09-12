#!/bin/bash
c="echo -e "
r=0
g=0
b=0
for (( ; r<255; r=$r+1 ))
   do
       c=${c}"\e[48;2;${r};${g};${b}m \033[0m"
   done
for (( ; g<255; g=$g+1 ))
   do
       c=${c}"\e[48;2;${r};${g};${b}m \033[0m"
   done
for (( ; r>0; r=$r-1 ))
   do
       c=${c}"\e[48;2;${r};${g};${b}m \033[0m"
   done
for (( ; b<255; b=$b+1 ))
   do
       c=${c}"\e[48;2;${r};${g};${b}m \033[0m"
   done
for (( ; g>0; g=$g-1 ))
   do
       c=${c}"\e[48;2;${r};${g};${b}m \033[0m"
   done
for (( ; r<255; r=$r+1 ))
   do
       c=${c}"\e[48;2;${r};${g};${b}m \033[0m"
   done
for (( ; g<255; g=$g+1 ))
   do
       c=${c}"\e[48;2;${r};${g};${b}m \033[0m"
   done
$c
