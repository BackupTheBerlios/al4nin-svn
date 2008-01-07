BEGIN { relevant = 0; line = 1 }
/@Haskell.*@Begin/ { relevant = 1; print "#line", line }
/@End.*@Haskell/ { relevant = 0 }



{ line++; if (relevant) { if (relevant > 1) print; relevant++ } }