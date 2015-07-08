# Makefile.am -- Backtrace Makefile.
# Copyright (C) 2012-2013 Free Software Foundation, Inc.

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:

#     (1) Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer. 

#     (2) Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in
#     the documentation and/or other materials provided with the
#     distribution.  

#     (3) The name of the author may not be used to
#     endorse or promote products derived from this software without
#     specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

AM_CFLAGS = $(EXTRA_FLAGS) $(WARN_FLAGS) $(PIC_FLAG) -I $(srcdir)/include -I $(top_builddir)
EXTRA_DIST=include/dwarf2.h\
		   include/dwarf2.def\
		   include/filenames.h

lib_LTLIBRARIES = lib/libbacktrace.la

lib_libbacktrace_la_SOURCES = \
	include/backtrace.h \
	src/dwarf.c \
	src/fileline.c \
	include/internal.h \
	src/posix.c \
	src/print.c \
	src/state.c

BACKTRACE_FILES = \
	src/backtrace.c \
	src/simple.c \
	src/nounwind.c

FORMAT_FILES = \
	src/elf.c \
	src/unknown.c

VIEW_FILES = \
	src/read.c \
	src/mmapio.c

ALLOC_FILES = \
	src/alloc.c \
	src/mmap.c

EXTRA_lib_libbacktrace_la_SOURCES = \
	$(BACKTRACE_FILES) \
	$(FORMAT_FILES) \
	$(VIEW_FILES) \
	$(ALLOC_FILES)


lib_libbacktrace_la_LIBADD = \
	$(BACKTRACE_FILE) \
	$(FORMAT_FILE) \
	$(VIEW_FILE) \
	$(ALLOC_FILE)

lib_libbacktrace_la_DEPENDENCIES = $(lib_libbacktrace_la_LIBADD)

include_HEADERS=\
				include/backtrace-supported.h\
				include/backtrace.h

# Testsuite.

check_PROGRAMS =

TESTS = $(check_PROGRAMS)

btest_SOURCES = src/btest.c
btest_CFLAGS = $(AM_CFLAGS) -g -O
btest_LDADD = lib/libbacktrace.la

check_PROGRAMS += btest


# We can't use automake's automatic dependency tracking, because it
# breaks when using bootstrap-lean.  Automatic dependency tracking
# with GCC bootstrap will cause some of the objects to depend on
# header files in prev-gcc/include, e.g., stddef.h and stdarg.h.  When
# using bootstrap-lean, prev-gcc is removed after each stage.  When
# running "make install", those header files will be gone, causing the
# library to be rebuilt at install time.  That may not succeed.

# These manual dependencies do not include dependencies on unwind.h,
# even though that is part of GCC, because where to find it depends on
# whether we are being built as a host library or a target library.

INCDIR = $(top_srcdir)/packaged/include
src/alloc.lo: $(top_top_builddir)/config.h include/backtrace.h include/internal.h
src/backtrace.lo: $(top_builddir)/config.h include/backtrace.h
src/btest.lo: $(INCDIR)/filenames.h include/backtrace.h include/backtrace-supported.h
src/dwarf.lo: $(top_builddir)/config.h $(INCDIR)/dwarf2.h $(INCDIR)/dwarf2.def \
	$(INCDIR)/filenames.h include/backtrace.h include/internal.h
src/elf.lo: $(top_builddir)/config.h include/backtrace.h include/internal.h
src/fileline.lo: $(top_builddir)/config.h include/backtrace.h include/internal.h
src/mmap.lo: $(top_builddir)/config.h include/backtrace.h include/internal.h
src/mmapio.lo: $(top_builddir)/config.h include/backtrace.h include/internal.h
src/nounwind.lo: $(top_builddir)/config.h include/internal.h
src/posix.lo: $(top_builddir)/config.h include/backtrace.h include/internal.h
src/print.lo: $(top_builddir)/config.h include/backtrace.h include/internal.h
src/read.lo: $(top_builddir)/config.h include/backtrace.h include/internal.h
src/simple.lo: $(top_builddir)/config.h include/backtrace.h include/internal.h
src/state.lo: $(top_builddir)/config.h include/backtrace.h include/backtrace-supported.h include/internal.h
src/unknown.lo: $(top_builddir)/config.h include/backtrace.h include/internal.h
