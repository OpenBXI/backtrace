#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.63])
define([BXIMODULE], backtrace)
AC_PACKAGE([BXIMODULE])
define([BXIMODULE_VERSION],[esyscmd([awk '/^%define version/ {print }' $1.spec | sed 's/.* //' | tr -d '\n'])])
AC_INIT(BXIMODULE, [BXIMODULE_VERSION(BXIMODULE)])
AC_CONFIG_AUX_DIR([.autotools_cache])
AM_INIT_AUTOMAKE([foreign subdir-objects])
AC_CONFIG_MACRO_DIR([.autotools_cache/m4])
AC_CONFIG_HEADERS([template_config.h])
AC_CONFIG_FILES([template_version.py])
AC_CONFIG_SRCDIR([packaged/src/backtrace.c])

# Checks for programs.
AC_PROG_CXX
AC_PROG_AWK
AC_PROG_CC
AC_PROG_CPP
AC_PROG_INSTALL
AC_PROG_LN_S
AC_PROG_MAKE_SET
LT_INIT
AM_PROG_CC_C_O


AM_CONDITIONAL([HAVE_SYSTEMD], [test "xyes" == "xno"])
# Checks for header files.
AC_CHECK_HEADERS([fcntl.h stddef.h stdint.h stdlib.h string.h unistd.h])

# Checks for typedefs, structures, and compiler characteristics.
AC_C_INLINE
AC_TYPE_INT32_T
AC_TYPE_INT64_T
AC_TYPE_OFF_T
AC_TYPE_SIZE_T
AC_TYPE_SSIZE_T
AC_TYPE_UINT16_T
AC_TYPE_UINT32_T
AC_TYPE_UINT64_T

# Checks for library functions.
AC_FUNC_MALLOC
AC_FUNC_MMAP
AC_FUNC_REALLOC
#AC_FUNC_STRNLEN
AC_CHECK_FUNCS([getpagesize memset munmap strdup strerror])

AC_PROG_AWK
case "$AWK" in
"") AC_MSG_ERROR([can't build without awk]) ;;
esac

LT_INIT([disable-shared])
AM_PROG_LIBTOOL

backtrace_supported=yes

AC_CHECK_HEADER([unwind.h],
  [AC_CHECK_FUNC([_Unwind_Backtrace],
  [BACKTRACE_FILE="src/backtrace.lo src/simple.lo"],
  [BACKTRACE_FILE="src/nounwind.lo" backtrace_supported=no])],
  [BACKTRACE_FILE="src/nounwind.lo" backtrace_supported=no])
AC_SUBST(BACKTRACE_FILE)

EXTRA_FLAGS=
AC_CACHE_CHECK([for -funwind-tables option],
  [libbacktrace_cv_c_unwind_tables],
  [CFLAGS_hold="$CFLAGS"
   CFLAGS="$CFLAGS -funwind-tables"
   AC_COMPILE_IFELSE(
     [AC_LANG_PROGRAM([static int f() { return 0; }], [return f();])],
     [libbacktrace_cv_c_unwind_tables=yes],
     [libbacktrace_cv_c_unwind_tables=no])
   CFLAGS="$CFLAGS_hold"])
if test "$libbacktrace_cv_c_unwind_tables" = "yes"; then
  EXTRA_FLAGS=-funwind-tables
fi
AC_CACHE_CHECK([for -frandom-seed=string option],
  [libbacktrace_cv_c_random_seed_string],
  [CFLAGS_hold="$CFLAGS"
   CFLAGS="$CFLAGS -frandom-seed=conftest.lo"
   AC_COMPILE_IFELSE(
     [AC_LANG_PROGRAM([], [return 0;])],
     [libbacktrace_cv_c_random_seed_string=yes],
     [libbacktrace_cv_c_random_seed_string=no])
   CFLAGS="$CFLAGS_hold"])
if test "$libbacktrace_cv_c_random_seed_string" = "yes"; then
  EXTRA_FLAGS="$EXTRA_FLAGS -frandom-seed=\$@"
fi
AC_SUBST(EXTRA_FLAGS)



AC_SUBST(WARN_FLAGS)

ac_save_CFFLAGS="$CFLAGS"
CFLAGS="$CFLAGS -Werror-implicit-function-declaration"
AC_MSG_CHECKING([for _Unwind_GetIPInfo])
AC_LINK_IFELSE(
  [AC_LANG_PROGRAM(
     [#include "unwind.h"
  struct _Unwind_Context *context;
  int ip_before_insn = 0;],
  [return _Unwind_GetIPInfo (context, &ip_before_insn);])],
  [have_unwind_getipinfo=yes], [have_unwind_getipinfo=no])
CFLAGS="$ac_save_CFLAGS"
AC_MSG_RESULT([$have_unwind_getipinfo])
if test "$have_unwind_getipinfo" = "yes"; then
  AC_DEFINE(HAVE_GETIPINFO, 1, [Define if _Unwind_GetIPInfo is available.])
fi

# When building as a target library, shared libraries may want to link
# this in.  We don't want to provide another shared library to
# complicate dependencies.  Instead, we just compile with -fPIC.
PIC_FLAG=
AC_SUBST(PIC_FLAG)

# Test for __sync support.
AC_CACHE_CHECK([__sync extensions],
[libbacktrace_cv_sys_sync],
   AC_LINK_IFELSE(
     [AC_LANG_PROGRAM([int i;],
                      [__sync_bool_compare_and_swap (&i, i, i);
                       __sync_lock_test_and_set (&i, 1);
                       __sync_lock_release (&i);])],
     [libbacktrace_cv_sys_sync=yes],
     [libbacktrace_cv_sys_sync=no])
 )
BACKTRACE_SUPPORTS_THREADS=0
if test "$libbacktrace_cv_sys_sync" = "yes"; then
  BACKTRACE_SUPPORTS_THREADS=1
  AC_DEFINE([HAVE_SYNC_FUNCTIONS], 1,
	    [Define to 1 if you have the __sync functions])
fi
AC_SUBST(BACKTRACE_SUPPORTS_THREADS)

# The library needs to be able to read the executable itself.  Compile
# a file to determine the executable format.  The awk script
# filetype.awk prints out the file type.
AC_CACHE_CHECK([output filetype],
[libbacktrace_cv_sys_filetype],
[filetype=
AC_COMPILE_IFELSE(
  [AC_LANG_PROGRAM([int i;], [int j;])],
  [filetype=`${AWK} -f $srcdir/filetype.awk conftest.$ac_objext`],
  [AC_MSG_FAILURE([compiler failed])])
libbacktrace_cv_sys_filetype=$filetype])

# Match the file type to decide what files to compile.
FORMAT_FILE=
case "$libbacktrace_cv_sys_filetype" in
elf*) FORMAT_FILE="src/elf.lo" ;;
*) AC_MSG_WARN([could not determine output file type])
   FORMAT_FILE="src/unknown.lo"
   backtrace_supported=no
   ;;
esac
AC_SUBST(FORMAT_FILE)

# ELF defines.
elfsize=
case "$libbacktrace_cv_sys_filetype" in
elf32) elfsize=32 ;;
elf64) elfsize=64 ;;
esac
AC_DEFINE_UNQUOTED([BACKTRACE_ELF_SIZE], [$elfsize], [ELF size: 32 or 64])

BACKTRACE_SUPPORTED=0
if test "$backtrace_supported" = "yes"; then
  BACKTRACE_SUPPORTED=1
fi
AC_SUBST(BACKTRACE_SUPPORTED)


AC_CHECK_HEADERS(sys/mman.h)
if test "$ac_cv_header_sys_mman_h" = "no"; then
  have_mmap=no
else
    AC_CHECK_FUNC(mmap, [have_mmap=yes], [have_mmap=no])
fi
if test "$have_mmap" = "no"; then
  VIEW_FILE=src/read.lo
  ALLOC_FILE=src/alloc.lo
else
  VIEW_FILE=src/mmapio.lo
  ALLOC_FILE=src/mmap.lo
fi
AC_SUBST(VIEW_FILE)
AC_SUBST(ALLOC_FILE)

BACKTRACE_USES_MALLOC=0
if test "$ALLOC_FILE" = "alloc.lo"; then
  BACKTRACE_USES_MALLOC=1
fi
AC_SUBST(BACKTRACE_USES_MALLOC)

# Check for dl_iterate_phdr.
AC_CHECK_HEADERS(link.h)
if test "$ac_cv_header_link_h" = "no"; then
  have_dl_iterate_phdr=no
else
    AC_CHECK_FUNC([dl_iterate_phdr], [have_dl_iterate_phdr=yes],
		  [have_dl_iterate_phdr=no])
fi
if test "$have_dl_iterate_phdr" = "yes"; then
  AC_DEFINE(HAVE_DL_ITERATE_PHDR, 1, [Define if dl_iterate_phdr is available.])
fi

# Check for the fcntl function.
  AC_CHECK_FUNC(fcntl, [have_fcntl=yes], [have_fcntl=no])
if test "$have_fcntl" = "yes"; then
  AC_DEFINE([HAVE_FCNTL], 1,
	    [Define to 1 if you have the fcntl function])
fi

AC_CHECK_DECLS(strnlen)

# Check for getexecname function.
AC_CHECK_FUNC(getexecname, [have_getexecname=yes], [have_getexecname=no])
if test "$have_getexecname" = "yes"; then
  AC_DEFINE(HAVE_GETEXECNAME, 1, [Define if getexecname is available.])
fi

AC_CACHE_CHECK([whether tests can run],
  [libbacktrace_cv_sys_native],
  [AC_RUN_IFELSE([AC_LANG_PROGRAM([], [return 0;])],
     [libbacktrace_cv_sys_native=yes],
     [libbacktrace_cv_sys_native=no],
     [libbacktrace_cv_sys_native=no])])
AM_CONDITIONAL(NATIVE, test "$libbacktrace_cv_sys_native" = "yes")

if test "${multilib}" = "yes"; then
  multilib_arg="--enable-multilib"
else
  multilib_arg=
fi
SUBPACKAGES="debuginfo devel"
AC_SUBST([SUBPACKAGES])
AC_BXIEXTRA_DIST=""
AC_SUBST([AC_BXIEXTRA_DIST])
#CFLAGS="$CFLAGS -D_GNU_SOURCE"
AC_CONFIG_FILES([Makefile packaged/Makefile packaged/backtrace-supported.h tests/Makefile])
AC_OUTPUT

echo "summary   :"
echo "          MODULE          : "BXIMODULE
echo "          VERSION         : "BXIMODULE_VERSION(BXIMODULE)
echo "          CC              : ${CC}"
echo "          CFLAGS          : ${CFLAGS}"
echo "          LDFLAGS         : ${LDFLAGS} ${LIBS}"
