#!/usr/bin/groovy
node {
    if (!env.NOSETESTS_ARGS) {
	env.NOSETESTS_ARGS=" --where=tests --match=\".*\\.((py)|c)\" --with-xunit --verbose --process-restartworker --process-timeout=60 --xunit-file=$WORKSPACE/tests/report/nosetests.xml"
	env.NOSETESTS_ARGS="$NOSETESTS_ARGS --with-coverage --cover-xml --cover-xml-file=$WORKSPACE/tests/report/py_coverage.xml --cover-html --cover-html-dir=$WORKSPACE/tests/report/py_html"
	env.NOSETESTS_ARGS="$NOSETESTS_ARGS --cover-inclusive  --cover-package=bxi"
    }
    if (!env.VALGRIND_ARGS) {
	env.VALGRIND_ARGS="--fair-sched=yes --child-silent-after-fork=yes --tool=memcheck --xml=yes --xml-file=$WORKSPACE/tests/report/valgrind/valgrind-%p.xml --leak-check=full --show-leak-kinds=all"
    }
    if (!env.GCOVR) {
	env.GCOVR="gcovr -v -r $WORKSPACE -e '.*usr/include' -e '.*local.*' -e '.*_.*' -x -o $WORKSPACE/tests/report/c_coverage.xml"
    }
    if (!env.PYTHONCONF) {
	env.PYTHONCONF="PYTHON=/usr/bin/python3"
    }

    stage('Checkout') {
	echo 'Checkouting..'
	checkout scm
    }

    stage('Build') {
	echo 'Building..'
	sh '''
	   sh bootstrap.sh;
	   mkdir -p .scanreport/;
	   scan-build ./configure --enable-gcov --enable-debug --enable-doc --enable-valgrind=\"$VALGRIND_ARGS\" --prefix=$WORKSPACE/install $PYTHONCONF
	   scan-build -k -o .scanbuild -v make
	   REPORT=\$( find .scanbuild -maxdepth 1 -not -empty -not -name '.scanbuild')
	   if [ $REPORT ] ; then
	   	cp -rf ${REPORT}/* .scanreport/
	   fi
	   rm -rf .scanbuild
	   '''
    }

    stage('Static Analysis') {
	echo "Analyzing.."
	sh "mkdir -p .slocdata; sloccount --datadir .slocdata --wide --details $WORKSPACE/packaged $WORKSPACE/tests $WORKSPACE/misc > sloccount.sc && echo 'sloccount complete' "

	echo "Running cppcheck"
	sh "cppcheck --enable=warning --enable=style --enable=performance --enable=portability --enable=information --enable=missingInclude --template=gcc --std=c99 --xml-version=2 $WORKSPACE/packaged/src/ $WORKSPACE/packaged/include/ 2> tests/report/cppcheck_results.xml && echo 'cppcheck complete' "

    }

    stage('Test') {
	echo 'Testing..'
    }

    stage('Install') {
	echo 'Installing..'
	sh "make install"
    }

    stage('Package') {
	echo "Packaging.."
	sh "make devrpm"
    }

    stage('Archiving') {
	echo "Archiving.."
	sh "tar -cf backtrace.tar archives"
	archiveArtifacts 'backtrace.tar'
    }

    stage('Report') {
	if (fileExists("tests/report/cunit-Results.xml")) {
	    sh "xsltproc -o tests/report/cunit.xml /usr/share/citools/cunit_to_junit.xsl tests/report/cunit-Results.xml"
	    junit "tests/report/cunit.xml"
	}
	if (fileExists("tests/report/cppcheck_results.xml")) {
	    sh "cppcheck_junit tests/report/cppcheck_results.xml tests/report/cppcheck.xml"
	    junit "tests/report/cppcheck.xml"
	}

	if (fileExists("tests/report/coverage.xml")) {
	    cobertura autoUpdateHealth: false, autoUpdateStability: false, coberturaReportFile: "**/tests/report/coverage.xml", conditionalCoverageTargets: '70, 0, 0', failNoReports: false, failUnhealthy: false, failUnstable: false, lineCoverageTargets: '80, 0, 0', maxNumberOfBuilds: 0, methodCoverageTargets: '80, 0, 0', onlyStable: false
	}
	sloccountPublish encoding: '', ignoreBuildFailure: true, pattern: 'sloccount.sc'
	publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: '.scanreport', reportFiles: 'index.html', reportName: 'Scan-Build reports', reportTitles: ''])
    }
}
