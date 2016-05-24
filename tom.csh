#!/usr/csh -f
foreach parent (*) 
echo $parent; end
foreach parent (*) 
if (-d $parent) then
#  (cd $parent; foreach file (commander*) set targetFile=`echo $file|sed s/commander/cmdr/`; mv $file $targetFile; end)
endif
end
exit
