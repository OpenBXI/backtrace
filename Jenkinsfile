#!/usr/bin/groovy
node {
    env.http_proxy="http://w3p2.atos-infogerance.fr:8080"
    env.https_proxy="http://w3p2.atos-infogerance.fr:8080"
    env.ftp_proxy="http://w3p2.atos-infogerance.fr:8080"

    stage('Checkout') {
	echo 'Checkouting..'
	checkout scm
    }

    stage('Build') {
	echo 'Building..'
	sh 'sh bootstrap.sh; autoconf; mkdir -p .scanreport; scan-build -k -o .scanbuild -v ./configure; scan-build -k -o .scanbuild -v make; cp -rf \$( find .scanbuild -maxdepth 1 -not -empty -not -name ".scanbuild")/* .scanreport/'
	sh 'rm -rf .scanbuild'
    }

    stage('Static Analysis') {
	echo "Analyzing.."
	sh "mkdir -p .slocdata; sloccount --datadir .slocdata --wide --details $WORKSPACE/packaged $WORKSPACE/tests $WORKSPACE/misc > sloccount.sc && echo 'sloccount complete' "

	echo "Running cppcheck"
	sh "cppcheck --enable=warning --enable=style --enable=performance --enable=portability --enable=information --enable=missingInclude --template=gcc --std=c99 --xml-version=2 $WORKSPACE/packaged/src/ $WORKSPACE/packaged/include/ 2> cppcheck_results.xml && echo 'cppcheck complete' "

	echo "Running pep8"
	sh "pycodestyle --config $WORKSPACE/misc/shared/pycodestyle.rc -r --statistics --count $WORKSPACE/misc/shared/ > pep8.txt || echo 'pep8 complete' "
	
	echo "Running pylint"
	sh "pylint -f parseable --rcfile=$WORKSPACE/misc/shared/pylint.rc > pylint.txt || echo 'pylint complete' "
	
	echo "Running valgrind"
	sh "valgrind --child-silent-after-fork=yes --leak-check=full --show-leak-kinds=all --xml=yes --xml-file=valgrind_results.xml libtool || echo 'valgrind complete'; xsltproc -o formatted_valgrind_results.xml /root/valgrind_to_junit.xsl valgrind_results.xml"
    }

    stage('Test') {
	echo 'Testing..'
	sh "mkdir -p .scanreport; scan-build -k -o .scanbuild -v make check; cp -rf \$( find .scanbuild -maxdepth 1 -not -empty -not -name '.scanbuild')/* .scanreport/"
	sh "rm -rf .scanbuild"
    }

    stage('Install') {
	echo 'Installing..'
	sh "mkdir -p .scanreport; scan-build -k -o .scanbuild -v make install; cp -rf \$( find .scanbuild -maxdepth 1 -not -empty -not -name '.scanbuild')/* .scanreport/"
	sh "rm -rf .scanbuild"
    }

    stage('Package') {
	echo "Packaging.."
	sh "mkdir -p .scanreport; scan-build -k -o .scanbuild -v make devrpm; cp -rf \$( find .scanbuild -maxdepth 1 -not -empty -not -name '.scanbuild')/* .scanreport/"
	sh "rm -rf .scanbuild"
    }

    stage('Report') {
	sh "cppcheck_junit cppcheck_results.xml formatted_cpp_results.xml"
	junit "formatted_cpp_results.xml" 
	junit "formatted_valgrind_results.xml"
	warnings canComputeNew: false, canResolveRelativePaths: false, canRunOnFailed: true, categoriesPattern: '', defaultEncoding: '', excludePattern: '', healthy: '', includePattern: '', messagesPattern: '', parserConfigurations: [[parserName: 'Pep8', pattern: 'pep8.txt'], [parserName: 'PyLint', pattern: 'pylint.txt']], unHealthy: ''
	sloccountPublish encoding: '', ignoreBuildFailure: true, pattern: 'sloccount.sc'
	publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: '.scanreport', reportFiles: 'index.html', reportName: 'Scan-Build reports', reportTitles: ''])
    }
}
