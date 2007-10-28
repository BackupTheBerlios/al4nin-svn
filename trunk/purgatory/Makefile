PLATFORM = $(shell uname)

ifeq (Darwin,$(PLATFORM))
LOUT = lout -F /gdm/psres
DISTILL = pstopdf
VIEWER = open
endif

ifeq (SunOS,$(PLATFORM))
LOUT = lout -F /home/ggreif/psres
DISTILL = unset XUSERFILESEARCHPATH && /vol/web/acro3.02/bin/distill
VIEWER = acroread
endif

.PHONY: view clean

%.pdf: %.ps
	$(DISTILL) $^

%.lout.ps: %.lout
	$(LOUT) -r2 -o $@ $^

view: Thrist.lout.pdf
	$(VIEWER) $^

clean:
	rm *.ps *.pdf *.li *.ld db/*.li
