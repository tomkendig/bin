#!/usr/sh -xf
for dir in `\ls`; do if [ -d $dir ]; then (cd $dir; for file in `\ls | grep commander`; do mv $file `echo $file|sed s/commander/cmdr/`; done); fi; done
exit
