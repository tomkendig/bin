#!/usr/sh -xf
ln -s /data/ftp/products/commander/release_2.2/2.2.1.14508 cmdr-2.2.1
#ln -s /data/ftp/products/commander/release_2.1/2.1.1.12064 cmdr-2.1.1
#(cd /data/ftp/customers/$customer; ln -s /data/ftp/products/commander/release_$release/$release.0.11419 cmdr-$release)
#for dir in `\ls`; do if [ -d $dir ]; then (cd $dir; for file in `\ls | grep commander`; do mv $file `echo $file|sed s/commander/cmdr/`; done); fi; done
exit
