TEXNAME=survey-cbvr


FHOME=.

TEXSRC_TEXT=$(shell find src/ -name "*.tex" -type f | tac )
TEXSRC_VEC=$(shell find vec/ -name "*.tex" -type f | tac )
TEXSRC=$(TEXNAME).tex $(TEXSRC_TEXT) $(TEXSRC_VEC)
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
# latex pdflatex xelatex

TEXF= -interaction=nonstopmode
VECF= -output-directory=vec-pdf
TEXC=$(TEXD)
IDXC=makeindex
SRTC=sort -u
RNMC=mv


PLOTC=gnuplot
PLOTSRC=$(shell find $(FHOME)/ -name "*.gnuplot" | tac )
PLOTOUT=$(patsubst %.gnuplot, %.table,$(PLOTSRC))

VECDIR=vec
VECSRC=$(VECDIR)
VECOUT=$(VECDIR)/out
VECPDF=$(VECDIR)/pdf
VECPDFBIG=$(VECDIR)/pdf-big
VECEPS=$(VECDIR)/eps
VECPS=$(VECDIR)/ps
VECSVG=$(VECDIR)/svg
VECPNG=$(VECDIR)/png
VECPNGFAST=$(VECDIR)/png/fast
VECPNGBIG=$(VECDIR)/png/big
VECTIFFFAST=$(VECDIR)/tiff/fast
VECTIFFBIG=$(VECDIR)/tiff/big


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

CONVERTDIR=@convertdir
FORMATS=native json docx odt epub epub3 fb2 html html5 s5 \
slidy slideous dzslides docbook opendocument latex beamer \
context texinfo man markdown markdown_strict \
markdown_phpextra markdown_github markdown_mmd plain rst \
mediawiki textile rtf org asciidoc

FLTDIR=@fltdir
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

TYPODIR=priv/typo
TYPOSOFTC=$(TYPODIR)/soft.py
TYPOC=$(TYPODIR)/typo.py

REPHRASE=([a-z:A-Z0-9./-]+)

COMMIT=$(shell git show | grep commit | cut -d' ' -f2)

CLSDIR=priv/csl
CLSSRC=$(CLSDIR)/gost-r-7-0-5-2008-numeric.csl

# Exec
# -====================================================================-

.PHONY: pandoc vec vec_compile

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
	pandoc -f latex  --latex-engine=xelatex -t $(to)  -sS --self-contained --toc --bibliography=$(BIBSRC) --csl $(CLSSRC)

_convertdir: $(FLTOUTS) $(TEXSRC)
	echo $(^D)			| \
	tr ' ' '\n' 			| \
	sed 's/^/$(CONVERTDIR)\/$(to)\//'	| \
	xargs -n 2 -P $(PROCN) mkdir -p



fltout: $(FLTOUTS)

$(FLTOUTS):  $(FLTSRC)
	$(foreach file,$^,$(FLATEXC) $(file) $(file).flt;)
	$(foreach file,$^,(cat $(file).flt | unix2dos | $(TYPOSOFTC) 1> $(file).tmp) \
		&& (cat $(file).tmp | tee $(file).flt &> /dev/null && rm $(file).tmp); )

typo:  $(TEXSRC_TEXT)
	$(foreach file,$^,(cat $(file) | unix2dos | $(TYPOSOFTC) 1> $(file).tmp) \
		&& (cat $(file).tmp | tee $(file) &> /dev/null && rm $(file).tmp); )

fltsrc: $(FLTSRC)

$(FLTSRC):  $(TEXSRC) | _mergedir vec_png

	$(foreach file,$^,\
	sed -re 's/\\subimport\{$(REPHRASE)\}\{$(REPHRASE)\}/\\input{$(shell readlink -m  $(FLTDIR) | sed 's/\//\\\//gi')\/$(shell dirname $(file) | sed 's/\//\\\//gi')\/\1\2}/gi' $(file) \
	| sed -re 's/.+%!nopandoc(.*)/\1/gi' \
	| sed -re 's/%!pandoc//gi' \
	| sed -re 's/\\npd.*\{(.*)\}/\1/gi' \
	| sed -re 's/\\pagebreak//gi' \
	| sed -re 's/\\import\{vec\/\}\{$(REPHRASE)\}/\\includegraphics{$(shell echo $(PWD)/${VECPNGFAST}/ | sed 's/\//\\\//gi' )\1.png}/gi' \
	| sed -re 's/\\cite\{$(REPHRASE)\}/\\citep{\1}/gi' \
	| sed -re 's/\\multirow\{.+\}\{.+\}\{(.+)\}/\1/gi' \
	| sed -re 's/\\Asection/\\section*/gi' \
	| sed -re 's/\\Csection/\\section*/gi' \
	| sed -re 's/\\byhand/ /gi' \
	| sed -re 's/figuredt/center/gi' \
	| sed -re 's/figured/center/gi' \
	| sed -re 's/\\fcaption/# Подпись: \\textit/gi' \
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

vec1:
	mkdir -p $(VECOUT)
	xelatex -output-directory=$(VECOUT) $(VECSRC)/$(to);
	mkdir -p $(VECPDF)
	pdfcrop "$(VECOUT)/$(to).pdf" "$(VECPDF)/$(to).pdf"
	convert "$(VECPDF)/$(to).pdf" "$(VECPNGFAST)$(to).png"
	mkdir -p $(VECPDFBIG)
	gs -dSAFER -dBATCH -dNOPAUSE -sDEVICE=pdfwrite \
	-dCompatibilityLevel=1.4  -dPDFFitPage -r300 -g3630x2720 \
	-sOutputFile=$(VECPDFBIG)/$(to).pdf $(VECPDF)/$(to).pdf
	mkdir -p $(VECPNGBIG);
	convert "$(VECPDFBIG)/$(to).pdf" "$(VECPNGBIG)$(to).png"


vec: vec_compile
	$(MAKE) vec_plot;
	$(MAKE) vec_compile;
	$(MAKE) vec_crop;
	$(MAKE) vec_eps;
	$(MAKE) vec_png;
	$(MAKE) vec_tiff
	$(MAKE) vec_png_big;

vec_png:
	mkdir -p $(VECPNGFAST);
	find $(VECPDF) -name "*.pdf" -type f -printf "%h/%f $(VECPNGFAST)/%f.png\n" | \
	sed 's/\.pdf\././' | \
	xargs -n 2 -P $(PROCN) convert;


vec_tiff:
	mkdir -p $(VECTIFFFAST);
	find $(VECPDF) -name "*.pdf" -type f -printf "%h/%f $(VECTIFFFAST)/%f.tiff\n" | \
	sed 's/\.pdf\././' | \
	xargs -n 2 -P $(PROCN) convert  -density 300;


vec_png_big: vec_pdf_big
	mkdir -p $(VECPNGBIG);
	find $(VECPDFBIG) -name "*.pdf" -type f -printf "%h/%f $(VECPNGBIG)/%f.png\n" | \
	sed 's/\.pdf\././' | \
	xargs -n 2 -P $(PROCN) convert;


vec_tiff_big: vec_pdf_big
	mkdir -p $(VECTIFFBIG);
	find $(VECPDFBIG) -name "*.pdf" -type f -printf "%h/%f $(VECTIFFBIG)/%f.tiff\n" | \
	sed 's/\.pdf\././' | \
	xargs -n 2 -P $(PROCN) convert -density 300;


vec_pdf_big:
	mkdir -p $(VECPDFBIG)
	find $(VECPDF) -name "*.pdf" -type f -printf "-sOutputFile=$(VECPDFBIG)/%f.big.pdf %h/%f\n" | \
	sed 's/\.pdf\././' | \
	xargs -n 2 -P $(PROCN) gs -dSAFER -dBATCH -dNOPAUSE -sDEVICE=pdfwrite \
	-dCompatibilityLevel=1.4  -dPDFFitPage -r300 -g3630x2720

vec_eps:
	mkdir -p $(VECEPS);
	find $(VECPDF) -name "*.pdf" -type f -printf "%h/%f $(VECEPS)/%f.ps\n" | \
	sed 's/\.pdf\././' | \
	xargs -n 2 -P $(PROCN) pdf2ps
	find $(VECEPS) -name "*.ps" -type f -exec ps2eps -a -f {} \;



vec_png_ink:
	mkdir -p $(VECPNG);
	find $(VECPDF) -name "*.pdf" -type f -printf "--file=%h/%f --export-eps=$(VECPNG)/%f.png\n" | \
	sed 's/\.pdf\././' | \
	xargs -n 2 -P $(PROCN) inkscape --without-gui

vec_svg_ink:
	mkdir -p $(VECSVG);
	find $(VECPDF) -name "*.pdf" -type f -printf "--file=%h/%f --export-eps=$(VECSVG)/%f.svg\n" | \
	sed 's/\.pdf\././' | \
	xargs -n 2 -P $(PROCN) inkscape --without-gui

vec_eps_ink:
	mkdir -p $(VECEPS);
	find $(VECPDF) -name "*.pdf" -type f -printf "--file=%h/%f --export-eps=$(VECEPS)/%f.eps\n" | \
	sed 's/\.pdf\././' | \
	xargs -n 2 -P $(PROCN) inkscape --without-gui

vec_crop:
	mkdir -p $(VECPDF);
	find $(VECOUT) -name "*.pdf" -type f -printf "%h/%f $(VECPDF)/%f\n" | \
	xargs -n 2 -P $(PROCN) $(CROPC)

vec_compile:
	mkdir -p $(VECOUT);
	find $(VECSRC) -name "*.tex" -type f  -print0 | \
	xargs -0 -n 1 -P $(PROCN) $(TEXC) -output-directory=$(VECOUT)

vec_plot:
	cd $(VECOUT) \
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

clean_all: clean clean_old clean_covert
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

