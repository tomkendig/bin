BEGIN {
	min_rate = 1000;
}
/Runnable step count/ {
	runnable_steps=$16; 
	noresource=0;
}
/No schedulable steps./ {
	runnable_steps=0;
	noresource=0;
}
/(No available resource)|(Updating wait-reason for resource-usage record to)/ {
	noresource++;
}
/Exiting scheduler with pending changes/ {
	partial_stepcount=$20;
}
/scheduleSteps.perform elapsed time/ {
	millis=$17;
	gsub(",","",millis); 
	gsub("ms","",millis); 
	if (runnable_steps>0) {
		if (runnable_steps > 0 && noresource > runnable_steps) {
			print "WARN: No resource count = " noresource " is GREATER than runnable steps = " runnable_steps;
		}
		else if (parital_stepcount > 0 && noresource > partial_stepcount) {
			print "WARN: No resource count = " noresource " is GREATER than partial stepcount = " partial_stepcount;
		}
		else {	
			if (partial_stepcount > 0) {
				processed_steps = partial_stepcount;
			} else {
				processed_steps = runnable_steps;
			}

			rate = processed_steps / millis;

			printf("Runnable: %8d, Processed: %8d, Scheduled: %8d, Time: %9.1fms, Processed Rate: %2.2f steps/ms\n", runnable_steps, processed_steps, processed_steps-noresource, millis, rate);

	
			sum_runs++;
			sum_runnable += runnable_steps;
			sum_processed += processed_steps;
			sum_noresource += noresource;
			sum_scheduled += (processed_steps-noresource);
			sum_millis += millis;

			if (rate > max_rate) {
				max_rate = rate;
			}
			if (rate < min_rate) {
				min_rate = rate;
			}
		}
	}
	else {
		#print "SKIPPED: Did not see 'runnable' line";
	}
	
	runnable_steps=0;
	partial_stepcount=0;
	noresource=0;
}
END {
	print "";
	print "Totals:"
	printf("Runnable: %8d, Processed: %8d, Scheduled: %8d, Time: %9.1fms\n", sum_runnable, sum_processed, sum_scheduled, sum_millis);
	print "";
	print "Averages:"
	printf("Runnable: %8d, Processed: %8d, Scheduled: %8d, Time: %9.1fms\n", sum_runnable/sum_runs, sum_processed/sum_runs, sum_scheduled/sum_runs, sum_millis/sum_runs);
	print "";
	print "Processing Rate:"
	printf("Avg Rate: %2.2f steps/ms, Min: %2.2f steps/ms, Max: %2.2f steps/ms\n", sum_processed/sum_millis, min_rate, max_rate);
}