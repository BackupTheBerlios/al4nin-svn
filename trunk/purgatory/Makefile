PLATFORM = $(shell uname)

ifeq (Darwin,$(PLATFORM))
LOUT = lout -F /gdm/psres
DISTILL = pstopdf
endif

ifeq (SunOS,$(PLATFORM))
LOUT = lout -F /home/ggreif/psres
DISTILL = unset XUSERFILESEARCHPATH && /vol/web/acro3.02/bin/distill
endif

%.pdf: %.ps
	$(DISTILL) $^

%.lout.ps: %.lout
	$(LOUT) -r2 -o $@ $^
