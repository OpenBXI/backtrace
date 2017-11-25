#!/usr/bin/groovy
node {
    env.NOSETESTS_ARGS=" --match=\".*\\.((py)|c)\" --where=$WORKSPACE/tests --with-xunit --verbose --process-restartworker --process-timeout=60 --xunit-file=$PWD/tests/report/nosetests_junit.xml"
    env.NOSETESTS_ARGS="$NOSETESTS_ARGS --with-coverage --cover-xml --cover-xml-file=$WORKSPACE/tests/reportpy_coverage.xml --cover-html --cover-html-dir=$WORKSPACE/tests/report/py_html"
    env.NOSETESTS_ARGS="$NOSETESTS_ARGS --cover-inclusive --cover-package=bxi "
    env.VALGRIND_ARGS="--fair-sched=yes --child-silent-after-fork=yes --tool=memcheck --xml=yes --xml-file=$WORKSPACE/tests/report/valgrind_result.xml"
    env.GCOVR="gcovr -v -r $WORKSPACE -e '.*usr/include' -e '.*local.*' -e '.*_.*' -x -o $WORKSPACE/tests/report/c_coverage.xml"

    stage('Checkout') {
	echo 'Checkouting..'
	checkout scm
    }

    stage('Build') {
	echo 'Building..'
	sh "sh bootstrap.sh; mkdir -p .scanreport; scan-build -k -o .scanbuild -v ./configure --enable-gcov --enable-debug --disable-doc --enable-valgrind=\"$VALGRIND_ARGS\" --prefix=\"$WORKSPACE\"/install"
	sh "scan-build -k -o .scanbuild -v make; cp -rf \$( find .scanbuild -maxdepth 1 -not -empty -not -name '.scanbuild')/* .scanreport/"
	sh 'rm -rf .scanbuild'
    }

    stage('Static Analysis') {
	echo "Analyzing.."
	sh "mkdir -p .slocdata; sloccount --datadir .slocdata --wide --details $WORKSPACE/packaged $WORKSPACE/tests $WORKSPACE/misc > sloccount.sc && echo 'sloccount complete' "

	echo "Running cppcheck"
	sh "cppcheck --enable=warning --enable=style --enable=performance --enable=portability --enable=information --enable=missingInclude --template=gcc --std=c99 --xml-version=2 $WORKSPACE/packaged/src/ $WORKSPACE/packaged/include/ 2> tests/report/cppcheck_results.xml && echo 'cppcheck complete' "

	echo "Running pep8"
	sh "pycodestyle --config $WORKSPACE/misc/shared/pycodestyle.rc -r --statistics --count $WORKSPACE/misc/shared/ > pep8.txt || echo 'pep8 complete' "
	
	echo "Running pylint"
	sh "pylint -f parseable --rcfile=$WORKSPACE/misc/shared/pylint.rc > pylint.txt || echo 'pylint complete' "
    }

    stage('Test') {
	echo 'Testing..'
	sh "mkdir -p .scanreport; scan-build -k -o .scanbuild -v make check VALGRIND=''; cp -rf \$( find .scanbuild -maxdepth 1 -not -empty -not -name '.scanbuild')/* .scanreport/"
	sh "rm -rf .scanbuild"
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
	sh "$WORKSPACE/misc/shared/cov_merge.py -o ./tests/report/coverage.xml ./tests/report/py_coverage.xml ./tests/report/c_coverage.xml"
	sh "cppcheck_junit tests/report/cppcheck_results.xml tests/report/cppcheck.xml"
	junit "tests/report/cppcheck.xml" 
	warnings canComputeNew: false, canResolveRelativePaths: false, canRunOnFailed: true, categoriesPattern: '', defaultEncoding: '', excludePattern: '', healthy: '', includePattern: '', messagesPattern: '', parserConfigurations: [[parserName: 'Pep8', pattern: 'pep8.txt'], [parserName: 'PyLint', pattern: 'pylint.txt']], unHealthy: ''
	sloccountPublish encoding: '', ignoreBuildFailure: true, pattern: 'sloccount.sc'
	publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: '.scanreport', reportFiles: 'index.html', reportName: 'Scan-Build reports', reportTitles: ''])
    }
}
