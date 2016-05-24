#!/usr/bin/env python
'''
gaps.py

Find timing gaps in Commander logs.

  > cat commander.log | gaps.py [--start <timestamp>] [--end <timestamp>] [--min <min-gap>]

Example

  $ cat /opt/electriccloud/electriccommander/logs/commander.log | gaps.py -s 2012-10-09T12:07:20 -e 2012-10-09T12:08:00

Precise only to the second.

'''

import sys
import getopt
import datetime
import time
import re

dtA = ''
secondsA = 0

#-----------------------------------------------------------------
def usage():
    """Help text"""
    print """
  > cat commander.log | gaps.py [--start <timestamp>] [--end <timestamp>] [--min <min-gap>]
"""

# Args
start = ""
end = ""
start_second = 0
end_second = 0
min_gap = 2  # seconds
verbose = 0
try:
    opts, args = getopt.getopt(sys.argv[1:], "s:e:m:v", ["start=", "end=", "min=", "verbose"])
except getopt.GetoptError, err:
    # print help information and exit:
    print str(err) # will print something like "option -a not recognized"
    usage()
    sys.exit(2)
for o, a in opts:
    if o in ("-s", "--start"):
        start = a
    elif o in ("-e", "--end"):
        end = a
    elif o in ("-m", "--min"):
        min_gap = int(a)
    elif o in ("-v", "--verbose"):
        verbose = 1
    else:
        assert False, "unhandled option"

# Start/End second
if(start):
    t = time.strptime(start, "%Y-%m-%dT%H:%M:%S")
    start_second = time.mktime(t)
if(end):
    t = time.strptime(end, "%Y-%m-%dT%H:%M:%S")
    end_second = time.mktime(t)


# # Temporarily read from a file
# with open("z.log") as f:
#     content = f.readlines()

p = re.compile(r"(\d+-\d+-\d+T\d+:\d+:\d+)")

gap_sum = 0
gap_cnt = 0
gap_max = 0

for line in sys.stdin:
#for line in content:
    m = p.match(line)
    if(m):
        dtB = m.group(1)
        if(not dtA):
            dtA = dtB # Initialize the first time through.

        t = time.strptime(dtB, "%Y-%m-%dT%H:%M:%S")
        secondsB = time.mktime(t)
        if(not secondsA):
            secondsA = secondsB # Initialize

        # Start second
        if(start_second and secondsA < start_second):
            secondsA = secondsB
            continue;

        # End second
        if(end_second and secondsB > end_second):
            break;

        # Gap and gap average
        gap = secondsB - secondsA
        if(gap >= min_gap):
            gap_sum += gap
            gap_cnt += 1
            if(gap > gap_max):
                gap_max = gap
            if(verbose):
                print dtA
                print dtB
                print "\tgap in seconds: %.f" % gap
                print
        dtA = dtB
        secondsA = secondsB

# Summary
print
print "  Start:   %s" % start
print "  End:     %s" % end
print "  Min gap: %d" % min_gap
print
print "  Gap Count:   %7d" % gap_cnt
print "  Gap Max:     %7d" % gap_max
print "  Gap Average: %7d" % (gap_sum / gap_cnt)
print
