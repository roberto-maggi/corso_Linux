#!/bin/bash

####
#
# scrivi uno script che numeri i file presenti nella cartella 
# e li sposti da 1 a 50 e da 51 a 100 in relative cartelle 
#
####

# for file in {1..100} ; do  touch $(cat /dev/urandom | env LC_CTYPE=C tr -cd 'a-f0-9' | head -c 32).txt ; done
mkdir -p 1-50 51-100
i=0
for file in $(find . -maxdepth 1 -type f -name "*\.txt" | sed 's|^./||'); do
    ((++i < 51)) || break
    mv $file 1-50/$i-$file
done
for file in $(find . -maxdepth 1 -type f -name "*\.txt" | sed 's|^./||'); do
    ((++i < 102)) || break
    mv $file 51-100/$i-$file
done