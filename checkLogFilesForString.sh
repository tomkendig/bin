for F in commander.*.log.zip ; do zcat $F > /tmp/tmp.log ; S="$(head -300 /tmp/tmp.log | awk '/^201[01]-/ {print $1}'| head -1)"; E="$(tail -300 /tmp/tmp.log | awk '/^201[01]-/ {print $1}' | tail -1)" ; if (grep -s 'Caught retryable exception ConstraintViolationException' /tmp/tmp.log > /dev/null ) ; then echo "xx : $F $S to $E" ; else echo "   : $F $S to $E" ; fi ; done

