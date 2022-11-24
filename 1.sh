#!/bin/bash
loadkeys ru
setfont ter-v18n
massdisk=()
grepmassdisk=""
sysdisk=""
disk=""
lsscsi | grep -viE "rom|usb" | awk '{print $NF}' | cut -b6-20
massdisk=($(lsscsi | grep -viE "rom|usb" | awk '{print $NF}' | cut -b6-20))
echo ${#massdisk[*]}
echo ${massdisk[*]}
if [ ${#massdisk[*]} = 1 ];
then
sysdisk="${massdisk[0]}"
elif [ ${#massdisk[*]} = 0 ];
then
echo -e "\033[41m\033[30mДоступных дисков не обнаружено\033[0m"
exit 0
else
echo -e "\033[41m\033[30mВведите метку диска (выделено красным) на который будет установлена ОС:\033[0m"
for (( j=0, i=1; i<="${#massdisk[*]}"; i++, j++ ))
do
echo ${massdisk[$j]}
grepmassdisk+="${massdisk[$j]}|"
echo -E "$grepmassdisk
"
done
lsscsi -s | grep -iE ""$grepmassdisk""
read -p ">" sysdisk
fi
