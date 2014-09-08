TEXNAME=survey-cbvr


HOME=.

TEXSRC1=$(shell find src/ -name "*.tex" -type f | tac )
TEXSRC2=$(shell find tikz/ -name "*.tex" -type f | tac )
TEXSRC=$(TEXNAME).tex $(TEXSRC1) $(TEXSRC2)
TEXPDF=$(TEXNAME).pdf
BIBSRC=./src/biblio/main.bib


TEXAUX=$(TEXNAME).aux
TEXBBL=$(TEXNAME).bbl

TEXIDX=$(TEXNAME).idx
TEXIND=$(TEXNAME).ind
INDSTY=styles/Index.ist

TEXGLS=$(TEXNAME).gls
TEXGLO=$(TEXNAME).glo
TEXIST=$(TEXNAME).ist


TXTPLAIN=$(TEXNAME).plain.txt
TXTLAYOUT=$(TEXNAME).layout.txt


HTMLINED=$(TEXNAME).Lined.html


# TeX -interaction=nonstopmode
# --------------------------------------
BIBC=bibtex
TEXD=xelatex
TEXF= -interaction=nonstopmode
TIKZF= -output-directory=tikz-pdf
TEXC=$(TEXD)
IDXC=makeindex
SRTC=sort -u
RNMC=mv


PLOTC=gnuplot
PLOTSRC=$(shell find $(HOME)/ -name "*.gnuplot" | tac )
PLOTOUT=$(patsubst %.gnuplot, %.table,$(PLOTSRC))

TIKZDIR=tikz
TIKZSRC=$(TIKZDIR)
TIKZOUT=$(TIKZDIR)/out
TIKZPDF=$(TIKZDIR)/pdf
TIKZPDFBIG=$(TIKZDIR)/pdf-big
TIKZEPS=$(TIKZDIR)/eps
TIKZPS=$(TIKZDIR)/ps
TIKZSVG=$(TIKZDIR)/svg
TIKZPNG=$(TIKZDIR)/png
TIKZPNGFAST=$(TIKZDIR)/png/fast
TIKZPNGBIG=$(TIKZDIR)/png/big

PROCN=4

NCODE=utf8
# koi8r оказался плох, из-за не алфавитного порядка русских букв.
XCODE=cp1251

N2XC=iconv -f "$(NCODE)" -t "$(XCODE)"
X2NC=iconv -f "$(XCODE)" -t "$(NCODE)"

DEL=rm -rf


CROPC=pdfcrop
TXTC=pdftotext
HTMC=pdftohtml

CONVERTDIR=__convertdir
FORMATS=native json docx odt epub epub3 fb2 html html5 s5 \
slidy slideous dzslides docbook opendocument latex beamer \
context texinfo man markdown markdown_strict \
markdown_phpextra markdown_github markdown_mmd plain rst \
mediawiki textile rtf org asciidoc

FLTDIR=__fltdir
FLTSRC1=$(FLTDIR)/$(TEXNAME).tex
FLTSRC=$(patsubst %, $(FLTDIR)/%,$(TEXSRC))

FLTOUTS=$(patsubst %.tex, $(FLTDIR)/%.tex.flt,$(TEXSRC))


FLTOUT=$(FLTDIR)/$(TEXNAME).tex.flt
FLTNAME=$(TEXNAME).tex.flt


CXX=g++
FLATEXDIR=priv/flatex
FLATEXC=$(FLATEXDIR)/flatex.py
FLATEXSDIR=$(FLATEXDIR)/src
FLATEXMOD=flatex utils
FLATEXSRC=$(patsubst %, $(FLATEXSDIR)/%.c,$(FLATEXMOD))

REPHRASE=([a-z:A-Z0-9./-]+)

CLSDIR=priv/csl
CLSSRC=$(CLSDIR)/gost-r-7-0-5-2008-numeric.csl

# Exec
# -====================================================================-

.PHONY: pandoc tikz tikz_compile

.SUFFIXES:
.SUFFIXES: .tex

# TeX
# --------------------------------------------------
all: pdf

pdf: $(TEXPDF)

$(TEXPDF):  $(TEXSRC) $(PLOTOUT) $(TEXAUX) $(TEXIND) $(TEXBBL)
	$(TEXC) $<
	make plot
	$(TEXC) $<


ind: $(TEXIND)

$(TEXIND): $(TEXIDX) $(INDSTY)
	$(SRTC)		$<		> $<.$(NCODE) 		\
	&& $(N2XC)	$<.$(NCODE) 	> $< 			\
	&& $(IDXC)	$< -s $(INDSTY) -o $@.$(XCODE) 		\
	&& $(X2NC)	$@.$(XCODE) 	>  $@

gls: $(TEXGLS)

$(TEXGLS): $(TEXGLO) $(TEXIST)
	$(SRTC)		$<		> $<.$(NCODE)	 	\
	&& $(N2XC)	$<.$(NCODE) 	> $< 			\
	&& $(IDXC)	-s $(TEXIST)  -o $@ $< 			\
	&& $(RNMC)	$@ 		$@.$(XCODE)		\
	&& $(X2NC)	$@.$(XCODE)	> $@;


bbl: $(TEXBBL)

$(TEXBBL): $(TEXAUX)
	$(BIBC) $<

$(TEXIDX): $(TEXSRC)
	$(TEXC) $<

$(TEXAUX): $(TEXSRC)
	$(TEXC) $<

plot: $(PLOTOUT)

$(PLOTOUT): $(PLOTSRC)
	$(PLOTC) $^


# -------------------------------------------------------------------------

define convert_builder
to_$(1): $(FLTSRC) $(TEXSRC)
	$(MAKE) convert to=$(1)
endef

$(foreach f,$(FORMATS),$(eval $(call convert_builder,$(f))))

convert_all:
	$(foreach f,$(FORMATS),echo convert to=$(f)) | \
	xargs -n 3 -P $(PROCN) $(MAKE)

convert:  _convertdir _convert

_convert: $(FLTOUTS) $(TEXSRC)
	echo $^			| \
	tr ' ' '\n' 		| \
	awk -F. '{print $$0 " -o $(CONVERTDIR)/$(to)/"$$1".$(to)" }' | \
	xargs -n 3 -P $(PROCN) \
	pandoc -f latex -t $(to) -sS --self-contained \
	--bibliography=$(BIBSRC) \
	--csl $(CLSSRC)

_convertdir: $(FLTOUTS) $(TEXSRC) 
	echo $(^D)			| \
	tr ' ' '\n' 			| \
	sed 's/^/$(CONVERTDIR)\/$(to)\//'	| \
	xargs -n 2 -P $(PROCN) mkdir -p



fltout: $(FLTOUTS)

$(FLTOUTS):  $(FLTSRC)
	$(foreach file,$^,$(FLATEXC) $(file) $(file).flt;)


fltsrc: $(FLTSRC)

$(FLTSRC):  $(TEXSRC) | _mergedir

	$(foreach file,$^,\
	sed -re 's/\\subimport\{$(REPHRASE)\}\{$(REPHRASE)\}/\\input{$(shell readlink -m  $(FLTDIR) | sed 's/\//\\\//gi')\/$(shell dirname $(file) | sed 's/\//\\\//gi')\/\1\2}/gi' $(file) \
	| sed -re 's/\\cite\{$(REPHRASE)\}/\\citep{\1}/gi' \
	| sed -re 's/\\multirow\{.+\}\{.+\}\{(.+)\}/\1/gi' \
	> $(FLTDIR)/$(file);)


# 	$(foreach file,$^,\
# 	sed -re 's/\\subimport\{$(REPHRASE)\}\{$(REPHRASE)\}/\\input{$(shell readlink -m  $(FLTDIR) | sed 's/\//\\\//gi')\/$(shell dirname $(file) | sed 's/\//\\\//gi')\/\1\2}/gi' $(file) \
# 	| sed -re 's/\\import\{$(REPHRASE)\}\{$(REPHRASE)\}/\\input{$(shell readlink -m $(FLTDIR) | sed 's/\//\\\//gi')\/\1\2}/gi' \
# 	> $(FLTDIR)/$(file);)


_mergedir: $(TEXSRC)
	echo $(^D)			| \
	tr ' ' '\n' 			| \
	sed 's/^/$(FLTDIR)\//'	| \
	xargs -n 2 -P $(PROCN) mkdir -p


layout: $(TXTLAYOUT)

$(TXTLAYOUT): $(TEXPDF)
	$(TXTC) -nopgbrk -layout  $< $@

text: $(TXTPLAIN)

$(TXTPLAIN): $(TEXPDF)
	$(TXTC) -nopgbrk $< $@

html: $(HTMLINED)

$(HTMLINED): $(TEXPDF)
	$(HTMC) -i -fontfullname -noframes -stdout  $< \
	| tr '\n' ' ' \
	| sed 's/\-<br\/> //gi' \
	| sed 's/<br\/> <b>/<br\/><br\/><b>/gi' \
	| sed 's/<\/b><br\/>/<\/b><br\/><br\/>/gi' \
	| sed 's/<br\/><br\/>/<p\/><p>/gi' \
	| sed 's/<br\/>//gi' \
	| sed -e 's/link to page [0-9]\+//gi' \
	| sed 's/#A0A0A0/white/gi' > $@


# -------------------------------------------------------------------------

tikz1:
	mkdir -p $(TIKZOUT)
	xelatex -output-directory=$(TIKZOUT) $(TIKZSRC)/$(to);
	mkdir -p $(TIKZPDF)
	pdfcrop "$(TIKZOUT)/$(to).pdf" "$(TIKZPDF)/$(to).pdf"
	convert "$(TIKZPDF)/$(to).pdf" "$(TIKZPNGFAST)$(to).png"
	mkdir -p $(TIKZPDFBIG)
	gs -dSAFER -dBATCH -dNOPAUSE -sDEVICE=pdfwrite \
	-dCompatibilityLevel=1.4  -dPDFFitPage -r300 -g3630x2720 \
	-sOutputFile=$(TIKZPDFBIG)/$(to).pdf $(TIKZPDF)/$(to).pdf
	mkdir -p $(TIKZPNGBIG);
	convert "$(TIKZPDFBIG)/$(to).pdf" "$(TIKZPNGBIG)$(to).png"


tikz: tikz_compile
	$(MAKE) tikz_plot;
	$(MAKE) tikz_compile;
	$(MAKE) tikz_crop;
	$(MAKE) tikz_eps;
	$(MAKE) tikz_png;
	$(MAKE) tikz_png_big;

tikz_png:
	mkdir -p $(TIKZPNGFAST);
	find $(TIKZPDF) -name "*.pdf" -type f -printf "%h/%f $(TIKZPNGFAST)/%f.png\n" | \
	sed 's/\.pdf\././' | \
	xargs -n 2 -P $(PROCN) convert;


tikz_png_big: tikz_pdf_big
	mkdir -p $(TIKZPNGBIG);
	find $(TIKZPDFBIG) -name "*.pdf" -type f -printf "%h/%f $(TIKZPNGBIG)/%f.png\n" | \
	sed 's/\.pdf\././' | \
	xargs -n 2 -P $(PROCN) convert;

tikz_pdf_big:
	mkdir -p $(TIKZPDFBIG)
	find $(TIKZPDF) -name "*.pdf" -type f -printf "-sOutputFile=$(TIKZPDFBIG)/%f.big.pdf %h/%f\n" | \
	sed 's/\.pdf\././' | \
	xargs -n 2 -P $(PROCN) gs -dSAFER -dBATCH -dNOPAUSE -sDEVICE=pdfwrite \
	-dCompatibilityLevel=1.4  -dPDFFitPage -r300 -g3630x2720

tikz_eps:
	mkdir -p $(TIKZEPS);
	find $(TIKZPDF) -name "*.pdf" -type f -printf "%h/%f $(TIKZEPS)/%f.ps\n" | \
	sed 's/\.pdf\././' | \
	xargs -n 2 -P $(PROCN) pdf2ps
	find $(TIKZEPS) -name "*.ps" -type f -exec ps2eps -a -f {} \;



tikz_png_ink:
	mkdir -p $(TIKZPNG);
	find $(TIKZPDF) -name "*.pdf" -type f -printf "--file=%h/%f --export-eps=$(TIKZPNG)/%f.png\n" | \
	sed 's/\.pdf\././' | \
	xargs -n 2 -P $(PROCN) inkscape --without-gui

tikz_svg_ink:
	mkdir -p $(TIKZSVG);
	find $(TIKZPDF) -name "*.pdf" -type f -printf "--file=%h/%f --export-eps=$(TIKZSVG)/%f.svg\n" | \
	sed 's/\.pdf\././' | \
	xargs -n 2 -P $(PROCN) inkscape --without-gui

tikz_eps_ink:
	mkdir -p $(TIKZEPS);
	find $(TIKZPDF) -name "*.pdf" -type f -printf "--file=%h/%f --export-eps=$(TIKZEPS)/%f.eps\n" | \
	sed 's/\.pdf\././' | \
	xargs -n 2 -P $(PROCN) inkscape --without-gui

tikz_crop:
	mkdir -p $(TIKZPDF);
	find $(TIKZOUT) -name "*.pdf" -type f -printf "%h/%f $(TIKZPDF)/%f\n" | \
	xargs -n 2 -P $(PROCN) $(CROPC)

tikz_compile:
	mkdir -p $(TIKZOUT);
	find $(TIKZSRC) -name "*.tex" -type f  -print0 | \
	xargs -0 -n 1 -P $(PROCN) $(TEXC) -output-directory=$(TIKZOUT)

tikz_plot:
	cd $(TIKZOUT) \
	&& find ./ -name "*.gnuplot" -type f -exec gnuplot {} \;


# --------------------------------------------------

scale: $(TEXNAME).x2.pdf

$(TEXNAME).x2.pdf : $(TEXPDF)
	gs -dSAFER -dBATCH -dNOPAUSE -sDEVICE=pdfwrite   \
	-dCompatibilityLevel=1.4  -dPDFFitPage -r150   \
	-g3630x2720 -sOutputFile=$@ $<

# --------------------------------------------------

pages: $(TEXPDF)
	gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER \
	-dFirstPage=$(from) \
	-dLastPage=$(to) \
	-sOutputFile="$(TEXNAME)_p$(from)-$(to).pdf" \
	$<

# Clean
# --------------------------------------------------
clean_old:
	@find ./ -name "*~" -type f -exec rm -f {} \;

clean_all: clean cleanold
	@$(DEL)				\
	"$(TEXNAME).pdf"		\
	"$(TEXNAME).html"

clean_covert:
	@$(DEL) 			\
	$(FLTNAME)			\
	$(CONVERTDIR)			\
	$(FLTDIR)

clean:
	@$(DEL) 			\
	*.gnuplot			\
	*.table				\
	"$(TEXNAME).acn"		\
	"$(TEXNAME).acr"		\
	"$(TEXNAME).alg"		\
	"$(TEXNAME).aux"		\
	"$(TEXNAME).bbl"		\
	"$(TEXNAME).blg"		\
	"$(TEXNAME).brf"		\
	"$(TEXNAME).glg"		\
	"$(TEXNAME).glo"		\
	"$(TEXNAME).gls"		\
	"$(TEXNAME).idx"		\
	"$(TEXNAME).ilg"		\
	"$(TEXNAME).ind"		\
	"$(TEXNAME).ist"		\
	"$(TEXNAME).log"		\
	"$(TEXNAME).out"		\
	"$(TEXNAME).toc"		\
	"$(TEXNAME).xdy"		\
	"$(TEXNAME).glo.$(NCODE)"	\
	"$(TEXNAME).gls.$(NCODE)"	\
	"$(TEXNAME).idx.$(NCODE)"	\
	"$(TEXNAME).ind.$(NCODE)"	\
	"$(TEXNAME).glo.$(XCODE)"	\
	"$(TEXNAME).gls.$(XCODE)"	\
	"$(TEXNAME).idx.$(XCODE)"	\
	"$(TEXNAME).ind.$(XCODE)"	\
	"$(TEXNAME).4ct"		\
	"$(TEXNAME).4tc"		\
	"$(TEXNAME).idv"		\
	"$(TEXNAME).lg"			\
	"$(TEXNAME).tmp"		\
	"$(TEXNAME).upa"		\
	"$(TEXNAME).upb"		\
	"$(TEXNAME).xdv"		\
	"$(TEXNAME).xref"		\
	"$(TEXNAME).css"		\
	"$(TEXNAME).dvi"

