define([BXIMODULE_VERSION],[esyscmd([awk '/^%define version/ {print }' $1.spec | sed 's/.* //' | tr -d '\n'])])
define([BXIMODULE_BRIEF],[esyscmd([awk '/^Summary:/ {print}' $1.spec | head -n 1 | sed 's/[^ \t]*[ \t]*\(.*\)/\1/' | tr -d '\n'])])
define([REPLACE_BRIEF],[
       BXIPROJECT_BRIEF="BXIMODULE_BRIEF($1)"
       AC_SUBST([BXIPROJECT_BRIEF])
])


define([ADD_BXISYSTEMD],[
       PKG_PROG_PKG_CONFIG
       AC_PROG_SED
       AC_ARG_WITH([systemdsysdir],
                        [AS_HELP_STRING([--with-systemdsysdir=DIR],
                                        [Directory for systemd service files])],
                        ,
                        [with_systemdsysdir=auto])
       AS_IF([test "x$with_systemdsysdir" = "xyes" -o "x$with_systemdsysdir" = "xauto"],
             [ def_systemdsystemunitdir=$($PKG_CONFIG --variable=systemdsystemunitdir systemd)

             if test $prefix != NONE; then
                 def_systemdsystemunitdir=$(echo $def_systemdsystemunitdir | $SED 's#'$($PKG_CONFIG  --variable=prefix systemd)'#'$prefix'#')
             fi

             AS_IF([test "x$def_systemdsystemunitdir" = "x"],
                   [AS_IF([test "x$with_systemdsysdir" = "xyes"],
                          [AC_MSG_ERROR([systemd support requested but pkg-config unable to query systemd package])])
                   with_systemdsysdir=no],
                   [with_systemdsysdir="$def_systemdsystemunitdir"])])
       AS_IF([test "x$with_systemdsysdir" != "xno"],
             [AC_SUBST([systemdsysdir], [$with_systemdsysdir])])
       AM_CONDITIONAL([HAVE_SYSTEMD], [test "x$with_systemdsysdir" != "xno"])
       ])

define([INIT_BXIPRODUCT],[
    AC_CONFIG_MACRO_DIR([.autotools_cache/m4])
    AC_CONFIG_AUX_DIR([.autotools_cache])
    AC_CONFIG_HEADERS([template_config.h])
    AC_CONFIG_FILES([template_version.py])
    AM_INIT_AUTOMAKE([foreign subdir-objects])

    if test "$2" == "systemd"; then
    ADD_BXISYSTEMD
    else
    AM_CONDITIONAL([HAVE_SYSTEMD], [test "xyes" = "xno"])
    fi

    AC_CHECK_PROGS([DOXYGEN], [doxygen])
    if test -z "$DOXYGEN"; then
        AC_MSG_WARN([Doxygen not found - continuing without Doxygen support])
    fi
    AC_CHECK_PROGS([DOT], [dot])
    if test -z "$DOT"; then
        AC_MSG_WARN([dot (graphviz) not found - continuing without dot support - The documentation will not be generated])
    fi
    AC_SUBST([BXIDOC_FOLDER])
    ])

define([DEFAULT_BXIOPTION],[
###########################
# debug
###########################
    AC_ARG_ENABLE([debug], [AS_HELP_STRING([--enable-debug], [enable debugging, default: yes])])
    if test x"$enable_debug" != "xno"; then
        CPPFLAGS="$CPPFLAGS -g3 -O0 ";
        CFLAGS="$CFLAGS -g3 -O0 ";
    fi

###########################
# gcov coverage reporting
###########################
    AC_ARG_ENABLE([gcov], [AS_HELP_STRING([--enable-gcov], [use Gcov to test the test suite , default: no])],)
    if test x"$enable_gcov" == "xyes"; then
        CFLAGS+=" --coverage"
        CPPFLAGS+=" --coverage"
        LDFLAGS+=" --coverage"
    else
        enable_gcov=no
    fi


###########################
# valgrind
###########################
    run_valgrind="no"
    AC_ARG_ENABLE([valgrind], [AS_HELP_STRING([--enable-valgrind[=args]], [use Valgrind to test the test suite])])
    if test x"$enable_valgrind" != "xno"; then
        AC_CHECK_PROG(VALGRIND_CHECK,valgrind,yes)
        if test x"$VALGRIND_CHECK" == "xyes"; then
            if test x"$enable_valgrind" == "xyes"; then
                enable_valgrind=""
            fi

            run_valgrind="yes"
            if test $# -eq 0; then
                VALGRIND='\$(abs_top_builddir)/libtool --mode=execute valgrind'
            fi
            if test $# -eq 1; then
                VALGRIND=$1
            fi
            AC_SUBST(VALGRIND)

        else
            AC_MSG_WARN([Please install valgrind before checking continuing without valgrind.])
            enable_valgrind=no
        fi

    fi
    if test x"$enable_valgrind" == "xno"; then
        enable_valgrind=""
    fi

    abs_path=$(readlink -f ${srcdir})

    VALGRIND_ARGS=" $enable_valgrind  --track-origins=yes --leak-check=full --show-reachable=yes --undef-value-errors=yes   --trace-children=no --child-silent-after-fork=yes --suppressions=${abs_path}/valgrind.supp "
    AC_SUBST(VALGRIND_ARGS)

###########################
# warnings
###########################
    AC_CHECK_PROGS([DOXYGEN], [doxygen])
    if test -z "$DOXYGEN"; then
        AC_MSG_WARN([Doxygen not found - continuing without Doxygen support])
    fi
    AC_CHECK_PROGS([DOT], [dot])
    if test -z "$DOT"; then
        AC_MSG_WARN([dot (graphviz) not found - continuing without dot support - The documentation will not be generated])
    fi
    AC_ARG_ENABLE([doc], [AS_HELP_STRING([--disable-doc], [disable the generation of the documentation])])
    if test x"$enable_doc" != "xno" ; then
        if ! test -z "$DOXYGEN";
        then
            if ! test -z "$DOT";
            then
                ENABLE_DOC="yes"
                AC_CONFIG_FILES([packaged/doc/Doxyfile packaged/doc/Doxyfile_specific])
            fi
        fi
    fi
    AM_CONDITIONAL([HAVE_DOXYGEN], [test x"$ENABLE_DOC" == "xyes"])
    if test x"$ENABLE_DOC" != "xyes"
    then
        ENABLE_DOC=no
    fi
    AC_ARG_ENABLE([check-doc], [AS_HELP_STRING([--enable-check-doc], [enable the documentation check])])
    AM_CONDITIONAL([CHECK_DOC], [test x"$enable_check_doc" == "xyes"])

    AC_ARG_ENABLE([mode-maintaners], [AS_HELP_STRING([--enable-mode-maintaners])])
    if test x"$enable_mode_maintaners" != "xno" ; then
        CPPFLAGS+=" -Wall -Werror  -Wextra -Wconversion "
    fi
###########################
    ])
define([BXIDISABLE_TESTS],[
    ENABLE_TESTS=yes
    AC_ARG_ENABLE([tests], [AS_HELP_STRING([--disable-tests] , [disable the tests])])
    if test x"$enable_tests" == "xno"
    then
        ENABLE_TESTS=no
    fi
    AM_CONDITIONAL([HAVE_TESTS], [test x"$ENABLE_TESTS" == "xyes"])
    ])

define([BXIDISABLE_PYTHON],[
    ENABLE_PYTHON=yes
    AC_ARG_ENABLE([python], [AS_HELP_STRING([--disable-python] , [disable the pyhon module])])
    if test x"$enable_python" == "xno"
    then
        ENABLE_PYTHON=no
    fi
    AM_CONDITIONAL([HAVE_PYTHON], [test x"$ENABLE_PYTHON" == "xyes"])
    ])

define([INIT_BXIPYTHON], [
	#AM_PATH_PYTHON
	PC_INIT([2.7], [2.99], , [AM_MSG_ERROR([Python not found])])
	PC_PYTHON_SITE_PACKAGE_DIR
	#PC_PYTHON_EXEC_PACKAGE_DIR
    PC_PYTHON_CHECK_MODULE([cffi], [], [AC_MSG_ERROR(Module not found)])
	])

define([FLAGS_BXITEST], [
################################ testing dependencies ############################
    OLD_CPPLFAGS=${CPPFLAGS}
    OLD_LDLFAGS=${LDFLAGS}
    OLD_LIBS=${LIBS}
#build flags specifical for test

    AC_SEARCH_LIBS([curs_set], [curses])
    AC_SEARCH_LIBS([CU_register_suites], [cunit])

    TST_CPPFLAGS=${CPPFLAGS}
    TST_CFLAGS=${CPPFLAGS}
    TST_CPPFLAGS=${CFLAGS}
    TST_LDFLAGS=${LDFLAGS}
    TST_LIBS=${LIBS}

#does the substitution inside the makefile
    AC_SUBST(TST_CPPFLAGS)
    AC_SUBST(TST_CFLAGS)
    AC_SUBST(TST_CPPFLAGS)
    AC_SUBST(TST_LDFLAGS)
    AC_SUBST(TST_LIBS)

    CPPFLAGS=${OLD_CPPLFAGS}
    LDFLAGS=${OLD_LDLFAGS}
    LIBS=${OLD_LIBS}
])

define([BXI_CHECK_C_COMPILER],[
    # Checks for programs.
    AC_PROG_CC_C99
    AM_PROG_CC_C_O
    AC_PROG_LIBTOOL
    AC_PROG_MKDIR_P
    AC_PROG_INSTALL


    #check the POSIX conformity
    AC_EGREP_CPP(posix_200809L_supported,
                 [#define _POSIX_C_SOURCE 200809L
                  #include <unistd.h>
                  #ifdef _POSIX_VERSION
                  #if _POSIX_VERSION == 200809L
                  posix_200809L_supported
                  #endif
                  #endif
                  ],
                  [],
                  [AC_MSG_FAILURE([*** Implementation must conform to the POSIX.1-2008 standard.])]
    )
    # Checks for header files.
    # if some header are optional you could add tests there and get the macro defined
    #AC_CHECK_HEADERS([stdbool.h])

    # Checks for typedefs, structures, and compiler characteristics.


    AC_CHECK_HEADER([stdbool.h],
                    [],
                    [AC_MSG_ERROR([stdbool.h cannot be found])],
                )
    AC_C_INLINE
    AC_TYPE_INT64_T
    AC_TYPE_PID_T
    AC_TYPE_SIZE_T
    AC_TYPE_UINT16_T
    AC_TYPE_UINT32_T
    AC_TYPE_UINT64_T
    AC_TYPE_UINT8_T
])


define([CHECK_PY_BXIBASE],[
       PC_PYTHON_CHECK_MODULE_REAL([bxibase], [bxi.base], [],
                                   [AC_MSG_ERROR([Module bxi.base provided by bxibase package not found])])
])
define([CHECK_PY_BXIUTIL],[
       PC_PYTHON_CHECK_MODULE_REAL([bxiutil], [bxi.util], [],
                                   [AC_MSG_ERROR([Module bxi.util provided by bxiutil package not found])]) ])
define([CHECK_PY_BXIAPI],[
       PC_PYTHON_CHECK_MODULE_REAL([bxiapi], [bxi.api], [],
                                   [AC_MSG_ERROR([Module bxi.api provided by bxiapi package not found])])
])
define([CHECK_C_BXIBASE],[
AC_CHECK_LIB([bxibase], [bxitime_get],[],
             [AC_MSG_ERROR([bxibase library provided by bxibase package not found])])
       ])
define([CHECK_C_BXIUTIL],[
AC_CHECK_LIB([bxiutil], [bximisc_readlink],[],
             [AC_MSG_ERROR([bxiutil library provided by bxiutil package not found])])
])
define([CHECK_C_BXIHWIF],[
AC_CHECK_LIB([bxihwif], [bxihwif_fmrts_parse],[],
             [AC_MSG_ERROR([bxihwif library provided by bxihwinterface package not found])])
])


define([CHECK_C_BXIAPI],[
AC_CHECK_LIB([bxiapi], [bxiapi_topo_init],[],
             [AC_MSG_ERROR([bxiapi library provided by bxiapi package not found])])
])

define([CHECK_C_BXIBB],[
AC_CHECK_LIB([bxibb], [bxibb_server_new],[],
             [AC_MSG_ERROR([bxibb library provided by bxibackbone package not found])])
])

define([DISPLAY_CONF],[
echo "summary   :"
echo "          MODULE          : "BXIMODULE
echo "          VERSION         : "BXIMODULE_VERSION($1)
echo "          CC              : ${CC}"
echo "          CPPFLAGS        : ${CPPFLAGS}"
echo "          LDFLAGS         : ${LDFLAGS} ${LIBS}"
echo
echo "          ENABLE_DOC      : ${ENABLE_DOC}"
echo "          ENABLE_PYTHON   : ${ENABLE_PYTHON}"
echo "          enable valgrind : $run_valgrind"
echo "          VALGRIND        : $VALGRIND"
echo "          GCOV            : ${enable_gcov}"
echo "          BRIEF           : BXIMODULE_BRIEF($1)"
echo
echo
echo "          python site dir : "${pythondir}
])

define([CHECK_MIBS], [
###########################
# mibdirs
###########################
# MIBDIRS should be defined, both at configure time and at compile time.
# It should contain paths containing relevant .mib files.
# pathes should not contain files defining the same module. (not obvious to test).
       AC_MSG_CHECKING(MIBDIRS definition)
       test -n "$MIBDIRS" || AC_MSG_ERROR([please set MIBDIRS variable])
       AC_MSG_RESULT([yes])

       AC_MSG_CHECKING(bxi mibs presence)
       command=$(snmptranslate -On BXI-DIVIO-FABRIC-MIB::portsNumber >/dev/null 2>&1)
       eval $command || AC_MSG_ERROR([Please fix MIBDIRS content or value, so as to have (${command}) test succeed.])
       AC_MSG_RESULT([yes])

###########################
# mib version
###########################
# mibs found in MIBDIRS should fit version used to develop.
# Note: operand here is ==, comparing actual mib to expected.
# the tool accepts other operators, they probaby need shell quoting
# (understood otherwise as redirections).
# same tests made in makefile.
    AC_MSG_CHECKING(bxi mibs version)
    abs_path=$(readlink -f ${srcdir})
    versionCheck=${abs_path}/packaged/bin/versionCheck.py
    AC_SUBST(versionCheck)
    command="$versionCheck BXI-DIVIO-MGMT.mib 201604040000Z"
    $command   ||  AC_MSG_ERROR([mib BXI-DIVIO-MGMT: wrong version])
    command="$versionCheck BXI-DIVIO-FABRIC.mib 201509121200Z"
    $command   ||  AC_MSG_ERROR([mib BXI-DIVIO-FABRIC: wrong version])
    AC_MSG_RESULT([yes])
])

define([CHECK_FLEX], [
AC_PROG_GREP
AC_PROG_SED
AC_PROG_LEX
AC_MSG_CHECKING([flex version])
flex_version=$($LEX --version | $GREP '^flex ' | $SED -e 's/^.\+ \([[0-9]]\+\.[[0-9]]\+\.[[0-9]]\+\)/\1/')
if test "$1" = "$flex_version"; then :
    AC_MSG_RESULT([yes])
    $2
    :
else
    AC_MSG_RESULT([no])
    $3
    :
fi
])
define([BXI_HEADER_FOLDER], [
AC_PROG_GREP
AC_PROG_SED
AC_MSG_CHECKING([header presence $1])
gcc_folder=$(echo '#include <$1>' | ${CC} -xc -M - | $GREP "$1" | $SED -e 's#^.*\s\([^ ]*\)$1\>.*#\1#')
if test $gcc_folder != ""; then :
    AC_MSG_RESULT([yes])
    :
else
    AC_MSG_RESULT([no])
    :
fi
BXIDOC_FOLDER="$gcc_folder $BXIDOC_FOLDER"
])
define([CHECK_BISON], [
AC_PROG_YACC
AC_MSG_CHECKING([bison version])
bison_version=$($YACC --version | $GREP '^bison ' | $SED -e 's/^.\+ \([[0-9]]\+\.[[0-9]]\+\)\(\.[[0-9]]\+-\?.*\)\?/\1/')
if test "$1" = "$bison_version"; then :
    AC_MSG_RESULT([yes])
    $2
    :
else
    AC_MSG_RESULT([no])
    $3
    :
fi
])


