# comparazioni_con_elif.sh
#!/bin/bash
# declare integers
NUM1=2
NUM2=1
if   [ $NUM1 -eq $NUM2 ]; then
	echo "Both values are equal"
elif [ $NUM1 -gt $NUM2 ]; then
	echo "NUM1 is greater than NUM2"
else 
	echo "NUM2 is greater than NUM1"
fi