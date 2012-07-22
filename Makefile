SOURCEMOD ?= ../sourcemod
OUTDIR ?= .

INCLUDE_DIRS = includes $(SOURCEMOD)/scripting/include

INCLUDES = customtags.inc keyvalues_stocks.inc configs.sp functions.sp
MODULES = CvarSettings.sp MapInfo.sp MatchMode.sp

DEPS = $(addprefix modules/, $(MODULES)) $(addprefix includes/, $(INCLUDES))
INCL = $(addprefix -i,$(INCLUDE_DIRS))
SPCOMP = $(SOURCEMOD)/scripting/spcomp
FLAGS = -v0

all: prep lgofnoc.smx

prep:
	mkdir -p $(OUTDIR)

lgofnoc.smx: lgofnoc.sp $(DEPS)
	$(SPCOMP) $(INCL) $(FLAGS) lgofnoc.sp -o$(OUTDIR)/$@

clean:
	rm -f $(OUTDIR)/lgofnoc.smx
