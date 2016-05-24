#!/bin/sh
for whichVersion in 401C 401B 4001 3102 3092 3081 3072 3063 ; do /net/f2home/tkendig/bin/installInternalGeneric.sh $whichVersion; done
grep -h batch /net/f2home/tkendig/results/*.txt | sort -u > /net/f2home/tkendig/results/summary.log
#cat /net/f2home/tkendig/results/gnuplot.cmd | gnuplot -p
#echo 'set term gif'; echo 'set output "createRate.gif '; echo 'plot "summary.log" using 8:1'; echo 'set output "deleteRate.gif"'; echo 'plot "summary.log" using 8:3'; echo 'set ticslevel 0 #starts the hight at zero'; echo 'set output "CreateRate3d.gif"'; echo 'splot "summary.log" using 8:10:1'; echo 'set output "deleteRate3d.gif"'; echo 'splot "summary.log" using 8:10:3'; |  gnuplot -p
