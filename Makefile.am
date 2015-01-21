
ACLOCAL_AMFLAGS="-I ./.autotools_cache/m4"

SUBDIRS=packaged


current_makefile=$(lastword $(MAKEFILE_LIST))
rpm_topdir=$(shell rpm --eval="%_topdir")
rpmdir=$(shell rpm --eval="%_rpmdir")
srcrpmdir=$(shell rpm --eval="%_srcrpmdir")
sourcedir=$(shell rpm --eval="%_sourcedir")

# TODO: specify your spec file here
specfile=$(top_srcdir)/@PACKAGE_NAME@.spec

# For release target (rt_)
# TODO: you may change that. See NovaForge for examples.
rt_project=exc_rd
rt_package=integration
rt_release=$(name)

# For (optionnal) doc target
#howto-basename= packaged/doc/HOWTO

# TODO: Here, you list all the files and directories you want to include
# with your release. When a directory is specified, all its content is
# taken into account recursively.
files=$(specfile) packaged/

#TODO: if you have man pages, list them here (they should be in the doc source folder)
man_files=

name=@PACKAGE_NAME@
version=@VERSION@
raw_release=$(shell awk '/^%define release/ {print $$NF}' $(specfile))
srelease=$(shell rpm --define='dist %{nil}' --eval=$(raw_release))
release=$(shell rpm --eval=$(raw_release))
arch=$(shell awk '/^BuildArch/ {print $$NF}' $(specfile))
pkg_dir= $(name)-$(version)
tarall= $(pkg_dir).tar.gz
spackage_name=$(pkg_dir)-$(srelease)
package_name=$(pkg_dir)-$(release)
srpm= $(srcrpmdir)/$(spackage_name).src.rpm
rpm= $(rpmdir)/$(arch)/$(package_name).$(arch).rpm
tar_srcdir=/tmp/$(USER)/$(pkg_dir)

# Default target: erase only produced files.
clean-local:
	rm -f *~ archives/$(shell basename $(rpm)) archives/$(shell basename $(srpm))

# Use this target to print out the version that will be produce
showversion:
	@version_from_spec $(specfile)

# Use this target to get information gathered by this Makefile.
# 'make config'
config:$(specfile)
	@echo "name:		$(name)"
	@echo "version:		$(version)"
	@echo "release:		$(release)"
	@echo "pkg_dir:		$(pkg_dir)"
	@echo "srpm:		$(srpm)"
	@echo "rpm:		$(rpm)"
	@echo "rt_project:	$(rt_project)"
	@echo "rt_package:	$(rt_package)"
	@echo "rt_release:	$(rt_release)"
	@echo "INFO: config OK"

# Documentation should not usually be included with your software
# since there is a documentation service that produces homogeneous,
# standardized documentation. Therefore, you can still write your
# documentation and archive it through CVS, but this documentation
# will have to be sent to Bull documentation service.  Anyway, this
# target allows the transformation of an OpenOffice file into a PDF
# and a TXT file using unoconv.
doc: config
	unoconv -d document -f pdf --stdout $(howto-basename).odt > $(howto-basename).pdf
	unoconv -d document -f txt --stdout $(howto-basename).odt > $(howto-basename).txt

# Copy required source files to a temporary directory. This directory
# will be tarred. The tar file will then be used by the rpmbuild
# command.
copy: config
	mkdir -p archives
	mkdir -p $(sourcedir)
	mkdir -p $(tar_srcdir)
	svn export --force $(top_srcdir) $(tar_srcdir)
	svnversion -c $(top_srcdir) | sed 's/.*:\(.*\)/\$$ Revision: \1 \$$/' > $(tar_srcdir)/svnversion
	rm -rf  `ls -d $(tar_srcdir)/*/ |grep -v packaged`
	cd $(tar_srcdir); mkdir tests; \
		touch tests/Makefile.am; \
		./bootstrap.sh; rm *.spec;


# Create the ChangeLog file and add changelog entries to the RPM .spec file.
# This step requires the 'svn2cl' tool.
# It is available here: http://arthurdejong.org/svn2cl/downloads.html
log: copy
	@if type svn2cl; then\
		svn2cl --group-by-day -o $(tar_srcdir)/ChangeLog;\
	else \
		echo ;echo ;\
		echo "*************************************************";\
		echo "You need the svn2cl tool in your PATH for";\
		echo "automatic log generation";\
		echo "Normally, it is available in you package manager.";\
		echo ;\
		echo "If this is not the case, please download it at:";\
		echo "http://arthurdejong.org/svn2cl/downloads.html";\
		exit 1;\
	fi;


log_devrpm: copy
	touch $(tar_srcdir)/ChangeLog

man: copy
	@for i in $(man_files);do \
		gzip -c packaged/doc/$$i > $(tar_srcdir)/doc/$$i.gz; \
	done

generate_rpm: man
	tar cvf $(sourcedir)/$(tarall) -C $(shell dirname $(tar_srcdir)) $(pkg_dir)
	rpmbuild -bb -v $(specfile) && echo "INFO: rpmbuild -bb -> OK"
	rpmbuild -bs -v --define='dist %{nil}' $(specfile) && echo "INFO: rpmbuild -bs -> OK"
	cp $(srpm) archives
	cp $(rpm) archives

# This target speed up the build process: it does not generate the
# changelog file. use only for development.
devrpm: copy log_devrpm generate_rpm

rpm: copy log generate_rpm

# auto_tag2 should be in your PATH
# This target is for tagging your software in the CVS tree.
# See DEV_PROCESS.readme for details.
tag: clean
	@echo -n "Launching the test suite? (y/N)"
	@read SURE; if test -n "$${SURE}" -a "$${SURE}" = "y";then make test;fi
	@if type auto_tag; then\
		auto_tag $(specfile);\
		autoreconf -f;\
		./config.status --recheck; \
	else\
		echo ;echo ;\
		echo "*************************************************";\
		echo "The script auto_tag cannot be found in your path!";\
		echo "Please install it!";\
		echo "For that purpose, I suggest you do something like:";\
		echo ;\
		echo "mkdir ~/.local/bull-exc-svn ~/.local/bin";\
		echo "cd ~/.local/bull-exc-svn";\
		echo "svn checkout https://nfbpshpc.frec.bull.fr:443/svn/hpcbxi/devtools/trunk devtools";\
		echo "ln -sf ~/.local/bull-exc-svn/devtools/bin/* ~/.local/bin/";\
		echo "export PATH=~/.local/bin:\$PATH";\
		echo ;\
		echo "Enjoy! ;-)";\
		exit 1;\
	fi;

compile_tests:
	make -C tests compile_tests

test:
	@PYTHONPATH=packaged/lib:$(PYTHONPATH)
	./bootstrap.sh; \
	./configure; \
	make; \
	make check; \
	make distclean

release: 
	@if type ask4release; then\
		ask4release $(current_makefile) $(specfile) $(rt_project) $(rt_package) $(rt_release);\
	else\
		echo ;echo ;\
		echo "*************************************************";\
		echo "The script ask4release cannot be found in your path!";\
		echo "Please install it!";\
		echo "For that purpose, I suggest you do something like:";\
		echo ;\
		echo "mkdir ~/.local/bull-exc-svn ~/.local/bin";\
		echo "cd ~/.local/bull-exc-svn";\
		echo "svn checkout https://nfbpshpc.frec.bull.fr:443/svn/hpcbxi/devtools/trunk devtools";\
		echo "ln -sf ~/.local/bull-exc-svn/devtools/bin/* ~/.local/bin/";\
		echo "export PATH=~/.local/bin:\$PATH";\
		echo ;\
		echo "Enjoy! ;-)";\
		exit 1;\
	fi;


BUILT_SOURCES=config.h
CLEANFILES=config.h

config.h:svnversion template_config.h
	cp template_config.h $@
	SVNVERSION=`sed 's/.*: //' $< | sed 's/ .*//'`;\
	echo "#define SVNVERSION $$SVNVERSION" >> $@


svnversion:
	SVNVER=$$(svnversion -c $(top_srcdir) | sed 's/.*:\(.*\)/\$$ Revision: \1 \$$/');\
	if test "$$SVNVER" = "Unversioned directory"; then \
		if ! test -z $(top_srcdir)/$@; then \
			if test $$? -ne 0; then \
				echo "\$$Revision: Unknown\$$" >> $@;\
			fi;\
			else \
			cp $(top_srcdir)/$@ $@;\
		fi;\
	else\
		echo $$SVNVER > $@;\
	fi

.PHONY:svnversion
