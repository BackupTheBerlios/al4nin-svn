PLATFORM = $(shell uname)

ifeq (Darwin,$(PLATFORM))
PSRES = /Users/ggreif/psres
LOUT = lout -F $(PSRES)
DISTILL = pstopdf
VIEWER = open
AWK = awk
endif

ifeq (SunOS,$(PLATFORM))
LOUT = lout -F /home/ggreif/psres
DISTILL = unset XUSERFILESEARCHPATH && /vol/web/acro3.02/bin/distill
VIEWER = acroread
AWK = gawk
endif

.PHONY: view clean check

%.pdf: %.ps
	$(DISTILL) $<

%.lout.ps: %.lout haskellx haskellfx db/*.ld
	$(LOUT) -r2 -o $@ $<

view: Thrist.lout.pdf
	$(VIEWER) $<

clean:
	rm *.ps *.pdf *.li *.ld db/*.li


check: Thrist.lout
	$(AWK) -f extract.awk < $<
