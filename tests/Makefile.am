
all-local:
	mkdir -p report

check-local:
	PYTHONPATH=${top_builddir}/packaged/lib/:$${PYTHONPATH} \
		nosetests ${top_srcdir} ${NOSETESTS_ARGS}
