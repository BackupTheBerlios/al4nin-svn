BEGIN { relevant = 0; line = 1; outp="" }
/@Haskell.*@Begin/ { relevant = 1; print "-- #line", line > outp }
/@End.*@Haskell/ { relevant = 0 }


{ line++; if (relevant) { if (relevant > 1) print > outp; relevant++ } }

/@TargetForExtract.*"/ { split($2, a, "\""); outp = a[2]; next }
