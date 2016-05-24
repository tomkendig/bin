unshift (@::gMatchers, 

    # junit test summary line:
    # [junit] Testsuite: com.electriccloud.commander.agent.AgentManagerTest
    # [junit] Tests run: 24, Failures: 3, Errors: 1, ...
    # [INFO] Tests run: 24, Failures: 3, Errors: 1, ...

	 {
        id =>               "junitSummary",
        pattern =>          q{^\s*\[.+\] Tests run: (\d+), }
	. q{Failures: (\d+), Errors: (\d+),},
        action =>           q{incValue("tests", $1);
			      if (($2 + $3) > 0) {
				  incValue("errors", $2 + $3);
				  my $start = 0;
                                        if (logLine($::gCurrentLine-1) =~
					    m/\[.+\] Testsuite:/) {
                                            $start = -1;
                                        }
				  diagnostic("", "error", $start);
			      }},
    },

    # Java compilations from Ant
    # [javac] Compiling 581 source files to ...
    #       or
    # [javac] Compiling 1 source file to ...
    #  [abcd] Compiling 10 source files to ...

	 {
        id =>               "javaCompiles",
        pattern =>          q{\[.+\] Compiling (\d+) source files? to},
        action =>           q{incValue("compiles", $1);},
    },

);
