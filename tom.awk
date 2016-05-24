BEGIN {
}

/All timers by name:/ {
	byNameIdx = 1;
	byRootIdx = 0;
	skip = 1;
}

/Timers by roots:/ {
	byNameIdx = 0;
	byRootIdx = 1;
	skip = 1;
}

/^$/ {
	skip = 1;
}

/^Name / {
	if (byNameIdx > 0) {
		byNameHeader = $0;
	}
	if (byRootIdx > 0) {
		byRootHeader = $0;
	}
	skip = 1;
}

/^-/ {
	if (byNameIdx > 0) {
		byNameHeaderSeparator = $0;
	}
	if (byRootIdx > 0) {
		byRootHeaderSeparator = $0;
	}
	skip = 1;
}

/^Totals / {
	if (byNameIdx > 0) {
		byNameTotals = $0;
		byNameTotalSum = $NF;
	}
	if (byRootIdx > 0) {
		byRootTotals = $0;
		byRootTotalSum = $NF;
	}
	skip = 1;
}

/<\/statistics>/ {
	byNameIdx = 0;
	byRootIdx = 0;
}

{
	if (!skip) {
		if (byNameIdx > 0) {
			byName[byNameIdx] = $0;
			field = NF - 4;
			byNameMean[sprintf("%20s",$field),byNameIdx] = byNameIdx;
			byNameSum[sprintf("%20s",$NF),byNameIdx] = byNameIdx;			
			byNameIdx++;
		}
	
		if (byRootIdx > 0) {
			byRoot[byRootIdx] = $0;
			field = NF - 4;
			byRootMean[sprintf("%20s",$field),byRootIdx] = byRootIdx;
			byRootSum[sprintf("%20s",$NF),byRootIdx] = byRootIdx;			
			byRootIdx++;
		}
	}
	
	skip = 0;
}

END {
	print "Top timers sorted by Mean:\n";
	print byNameHeader;
	print byNameHeaderSeparator;
	
	n = asorti(byNameMean);
	for (x = n; x >= n-25; x--) {
		split(byNameMean[x],tmp,SUBSEP);
		#print "tmp[1]=" tmp[1] " tmp[2]= " tmp[2];
		print byName[tmp[2]];
	}
	print byNameHeaderSeparator;
	print byNameTotals;
	
	print "\n";
	print "Top timers sorted by Sum:";
	printf ("%s %Total\n", byNameHeader);
	printf ("%s ------\n", byNameHeaderSeparator);

	n = asorti(byNameSum);
	for (x = n; x >= n-25; x--) {
		split(byNameSum[x],tmp,SUBSEP);
		#print "tmp[1]=" tmp[1] " tmp[2]= " tmp[2];
		printf("%s %5.2f\n", byName[tmp[2]], tmp[1]/byNameTotalSum*100);
	}
	printf ("%s ------\n", byNameHeaderSeparator);
	print byNameTotals;

#	print "\n";
#	print byRootHeader;
#	print byRootHeaderSeparator;
#
#	n = asorti(byRootMean);
#	for (x = n; x >= n-25; x--) {
#		split(byRootMean[x],tmp,SUBSEP);
#		#print "tmp[1]=" tmp[1] " tmp[2]= " tmp[2];
#		print byRoot[tmp[2]];
#	}
#	print byRootHeaderSeparator;
#	print byRootTotals;
}
