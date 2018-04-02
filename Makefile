#
# GEDA targets
#

# Read the name and schema files from the GEDA project file:
PROJECT=project
NAME    := $(shell sed -n 's/^output-name //p' $(PROJECT))
SCHEMAS := $(shell sed -n 's/^schematics //p' $(PROJECT))
V := @
Q := $(V:1=)

QUIET_GSCH2PCB = $(Q:@=@echo   GSCH2PCB $@ &)gsch2pcb
QUIET_GNETLIST = $(Q:@=@echo   GNETLIST $@ &)gnetlist

pcb: $(NAME).net
bom: $(NAME).bom
drc: $(NAME).drc
gerber: $(NAME).zip
render: $(NAME).png
pdf: $(NAME).pdf

$(NAME).net: $(SCHEMAS)
	$(QUIET_GSCH2PCB) --use-files $(PROJECT)

$(NAME).bom: $(SCHEMAS) attribs
	$(QUIET_GNETLIST) -g bom -o $@ -- $(SCHEMAS)

$(NAME).drc: $(SCHEMAS)
	$(QUIET_GNETLIST) -g drc2 -o - -- $^

# Use Hackvana style for SeeedStudio Fusion.
# SeeedStudio Design for Manufacture documentation:
#   https://statics3.seeedstudio.com/fusion/ebook/PCB+DFM+V1.0+.pdf
# Minimum spacings:
#   min trace width 4mil min trace spacing 4mil
#   min space between trace and pour 8mil
#   min space between vias 12mil
#   min space between trace and PTH 12mil
#   min annular ring 6mil
#   min silk width 4mil
#
#   Top Layer $(NAME).gtl
#   Top Solder Mask: $(NAME).gts
#   Top Silkscreen: $(NAME).gto
#   Top solderpaste: $(NAME).gtp
#   Bottom Layer $(NAME).gbl
#   Bottom Solder Mask: $(NAME).gbs
#   Bottom Silkscreen: $(NAME).gbo
#   Drills: $(NAME).txt
#   Milling layer (outline): $(NAME).gm1 (Seeed state .GML)
# We get this additional file
#   Fabrication information: $(NAME).fab
# and SeeedStudio appears to use this (at least the outline).
#
$(NAME).zip: $(NAME).pcb
	$(RM) -f gerber/* $@
	mkdir -p gerber
	pcb -x gerber --gerberfile "gerber/$(NAME)" --name-style hackvana $(NAME).pcb
	merge_drills.pl gerber/$(NAME)*.drl > gerber/$(NAME).txt
	rm gerber/$(NAME)*.drl
	zip -j $@ gerber/*

$(NAME).png: $(NAME).pcb
	pcbrender $^ $(NAME).png

$(NAME).pdf: $(SCHEMAS)
	gaf export --paper=iso_a4 --color --output=$@ $^

check-names:
	@echo PROJECT $(PROJECT)
	@echo NAME $(NAME)
	@echo SCHEMAS $(SCHEMAS)

clean:
	-@$(RM) -f $(addprefix $(NAME), .bom .new.pcb .elf .hex)

.PHONY: drc bom update clean gerber
.SECONDARY: $(addsuffix .elf, $(NAME)) $(OBJS)
