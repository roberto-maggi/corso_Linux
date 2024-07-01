# declare_array.sh
#!/bin/bash
ARRAY=( 'Debian Linux' 'Redhat Linux' Ubuntu Linux )
ELEMENTS=${#ARRAY[@]}
for (( i=0;i<$ELEMENTS;i++)); do
    echo ${ARRAY[${i}]}
done