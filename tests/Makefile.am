
all-local:
	mkdir -p report

check-local:
	PYTHONPATH=${abs_top_builddir}/packaged/lib/:$${PYTHONPATH} \
		nosetests -w ${abs_top_srcdir} ${NOSETESTS_ARGS}
