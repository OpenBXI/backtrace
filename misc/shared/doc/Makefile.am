if HAVE_DOXYGEN
docpkg = $(PACKAGE_TARNAME)-doxy-$(PACKAGE_VERSION).tar.gz

TAGFILEPATT = $(tagfiles_prefix)/\1/$(tagfiles_suffix)
HTMLDIRPATT = $(htmldirs_prefix)/\1/$(htmldirs_suffix)
# If the prefixes or suffixes contain a `#`, this will break.

.SECONDARY: doxygen.tag
doxygen.tag:
	@echo "Creating Doxyfile_specific_tagfiles"
	DOCSREQUIRED=$$(\
		grep '^BuildRequires:.*-doc' \
			"$(top_srcdir)/$(PACKAGE_NAME).spec" | \
		grep -o "[^: \t]*-doc" | \
		sed "s#\(.*\)-doc#$(TAGFILEPATT)=$(HTMLDIRPATT)#") ; \
	./gen_doxydeps.sh Doxyfile_specific_tagfiles $$DOCSREQUIRED
	$(DOXYGEN) Doxyfile
	if test $$(cat doxygen.warn | wc -l) -ne 0; \
	then \
		cat doxygen.warn ; \
	fi
#rm Doxyfile_specific_tagfiles

if CHECK_DOC
check_doc:
	if test $$(cat doxygen.warn | wc -l) -ne 0 ; \
	then \
		cat doxygen.warn ; \
		exit 1 ; \
	fi
else
check_doc:
	echo "No check of the documentation"
endif


$(docpkg): doxygen.tag
	cd html && tar czf ../$@ .

doc: doxygen.tag
	mkdir -p img

all-local: doxygen.tag check_doc

clean-local:
	rm -rf html doxygen.warn latex

doc_DATA = $(docpkg) doxygen.tag

install-data-hook:
	test -e $(DESTDIR)$(docdir)/$(PACKAGE_VERSION)/ \
	&& ( \
		printf "directory $(DESTDIR)$(docdir)/$(PACKAGE_VERSION)/ exists; " ; \
		echo "continue without installing the documentation" ; \
		exit 0 ; \
	) ; \
	mkdir $(DESTDIR)$(docdir)/$(PACKAGE_VERSION)/ ; \
	cd $(DESTDIR)$(docdir)/$(PACKAGE_VERSION)/ ; \
	tar xf ../$(docpkg) && rm -f ../$(docpkg)

uninstall-local:
	cd $(DESTDIR)$(docdir)/ && rm -rf $(PACKAGE_VERSION)

CLEANFILES = $(doc_DATA)
endif

EXTRA_DIST = README.md

