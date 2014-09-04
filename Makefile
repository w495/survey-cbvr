TEXNAME=survey-cbvr


HOME=.

TEXSRC=$(shell find $(HOME)/ -name "*.tex" -type f | tac )
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

RDIR=parts

TXTC=pdftotext
HTMC=pdftohtml


PLOTC=gnuplot
PLOTSRC=$(shell find $(HOME)/ -name "*.gnuplot" | tac )
PLOTOUT=$(patsubst %.gnuplot, %.table,$(PLOTSRC))

CONVERTDIR=pandoc
FORMATS=native json docx odt epub epub3 fb2 html html5 s5 \
slidy slideous dzslides docbook opendocument latex beamer \
context texinfo man markdown markdown_strict \
markdown_phpextra markdown_github markdown_mmd plain rst \
mediawiki textile rtf org asciidoc


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

CROPC=pdfcrop

PROCN=4


# Encoding
# --------------------------------------
NCODE=utf8
# koi8r оказался плох, из-за не алфавитного порядка русских букв.
XCODE=cp1251

N2XC=iconv -f "$(NCODE)" -t "$(XCODE)"
X2NC=iconv -f "$(XCODE)" -t "$(NCODE)"

# Clean
# --------------------------------------
DEL=rm -rf

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
to_$(1): $(TEXSRC)
	$(MAKE) convert to=$(1)
endef

$(foreach f,$(FORMATS),$(eval $(call convert_builder,$(f))))

convert_all:
	$(foreach f,$(FORMATS),echo convert to=$(f)) | \
	xargs -n 3 -P $(PROCN) $(MAKE)

convert:  _convertdir _convert

_convert: $(TEXSRC)
	echo $^			| \
	tr ' ' '\n' 		| \
	awk -F. '{print $$0 " -o $(CONVERTDIR)/$(to)/"$$1".$(to)" }' | \
	xargs -n 3 -P $(PROCN) \
	pandoc -f latex -t $(to) -sS --self-contained \
	--bibliography=$(BIBSRC)


_convertdir: $(TEXSRC)
	echo $(^D)			| \
	tr ' ' '\n' 			| \
	sed 's/^/$(CONVERTDIR)\/$(to)\//'	| \
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
tilda_clean:
	@find ./ -name "*~" -type f -exec rm -f {} \;

pandoc_clean:
	$(foreach f,$(FORMATS),$(DEL) $(CONVERTDIR)/$(f);)


clean_all: clean cleanold
	$(DEL) "$(TEXNAME).pdf"
	$(DEL) "$(TEXNAME).html"

clean:
	$(DEL) *.gnuplot
	$(DEL) *.table
	$(DEL) "$(TEXNAME).acn"
	$(DEL) "$(TEXNAME).acr"
	$(DEL) "$(TEXNAME).alg"
	$(DEL) "$(TEXNAME).aux"
	$(DEL) "$(TEXNAME).bbl"
	$(DEL) "$(TEXNAME).blg"
	$(DEL) "$(TEXNAME).brf"
	$(DEL) "$(TEXNAME).glg"
	$(DEL) "$(TEXNAME).glo"
	$(DEL) "$(TEXNAME).gls"
	$(DEL) "$(TEXNAME).idx"
	$(DEL) "$(TEXNAME).ilg"
	$(DEL) "$(TEXNAME).ind"
	$(DEL) "$(TEXNAME).ist"
	$(DEL) "$(TEXNAME).log"
	$(DEL) "$(TEXNAME).out"
	$(DEL) "$(TEXNAME).toc"
	$(DEL) "$(TEXNAME).xdy"
	$(DEL) "$(TEXNAME).glo.$(NCODE)"
	$(DEL) "$(TEXNAME).gls.$(NCODE)"
	$(DEL) "$(TEXNAME).idx.$(NCODE)"
	$(DEL) "$(TEXNAME).ind.$(NCODE)"
	$(DEL) "$(TEXNAME).glo.$(XCODE)"
	$(DEL) "$(TEXNAME).gls.$(XCODE)"
	$(DEL) "$(TEXNAME).idx.$(XCODE)"
	$(DEL) "$(TEXNAME).ind.$(XCODE)"
	$(DEL) "$(TEXNAME).4ct"
	$(DEL) "$(TEXNAME).4tc"
	$(DEL) "$(TEXNAME).idv"
	$(DEL) "$(TEXNAME).lg"
	$(DEL) "$(TEXNAME).tmp"
	$(DEL) "$(TEXNAME).upa"
	$(DEL) "$(TEXNAME).upb"
	$(DEL) "$(TEXNAME).xdv"
	$(DEL) "$(TEXNAME).xref"
	$(DEL) "$(TEXNAME).css"
	$(DEL) "$(TEXNAME).dvi"

