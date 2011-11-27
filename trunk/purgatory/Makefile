PLATFORM = $(shell uname)

CC = gcc

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

prg2lout: prg2lout.c
	$(CC) -O2 $< -o $@

%.pdf: %.ps
	$(DISTILL) $<

Thrist.lout.ps: haskellx haskellfx db/*.ld prg2lout db/*.LCM

%.lout.ps: %.lout
	$(LOUT) -C db -r2 -o $@ $<

view: Thrist.lout.pdf
	$(VIEWER) $<

clean:
	rm *.ps *.pdf *.li *.ld db/*.li


check: Thrist.lout
	$(AWK) -f extract.awk < $<
	cat check/Parser.incomplete* | sed -e "s/  | .../--  | .../1" > check/Parser.omg
	cat check/Machine.part* > check/Machine.omg
