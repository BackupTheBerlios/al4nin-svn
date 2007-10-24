LOUT = lout -F /home/ggreif/psres

DISTILL = unset XUSERFILESEARCHPATH && /vol/web/acro3.02/bin/distill

%.pdf: %.ps
	$(DISTILL) $^

%.lout.ps: %.lout
	$(LOUT) -r2 -o $@ $^
