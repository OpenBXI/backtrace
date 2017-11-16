#!/usr/bin/groovy
node {
    env.http_proxy="http://w3p2.atos-infogerance.fr:8080"
    env.https_proxy="http://w3p2.atos-infogerance.fr:8080"
    env.ftp_proxy="http://w3p2.atos-infogerance.fr:8080"

    stage('Checkout') {
	echo 'Checkouting..'
	sh "eval \$(ssh-agent); ssh-add;"
	checkout scm
    }

    stage('Build') {
	echo 'Building..'
	sh 'sh bootstrap.sh; autoconf; mkdir -p .scanreport; scan-build -k -o .scanbuild -v ./configure; scan-build -k -o .scanbuild -v make; mv \$( find .scanbuild -maxdepth 1 -not -empty -not -name ".scanbuild")/* .scanreport/'
	sh 'rm -rf .scanbuild'
    }

    stage('Static Analysis') {
	echo "Analyzing.."
	sh "mkdir -p .slocdata; sloccount --datadir .slocdata --wide --details $WORKSPACE/*/packaged $WORKSPACE/*/tests $WORKSPACE/*/misc > sloccount.sc && echo 'sloccount complete' "

	echo "Running cppcheck"
	sh "cppcheck --enable=warning --enable=style --enable=performance --enable=portability --enable=information --enable==missingInclude --template=gcc --std=c99 --xml-version=2 $WORKSPACE/*/packaged/src/ $WORKSPACE/*/packaged/include/ 2> cppcheck_results.xml && echo 'cppcheck complete' "

	echo "Running pep8"
	sh "pep8 -r --statistics --count $WORKSPACE/*/packaged/lib/ $WORKSPACE/*/packaged/bin/ --statistics > pep8.txt && echo 'pep8 complete' "
    }

    stage('Test') {
	echo 'Testing..'
	sh "mkdir -p .scanreport; scan-build -k -o .scanbuild -v make check; mv -f \$( find .scanbuild -maxdepth 1 -not -empty -not -name '.scanbuild')/* .scanreport/"
	sh "rm -rf .scanbuild"
    }

    stage('Install') {
	echo 'Installing..'
	sh "mkdir -p .scanreport; scan-build -k -o .scanbuild -v make install; tar -xfmv -f \$( find .scanbuild -maxdepth 1 -not -empty -not -name '.scanbuild')/* .scanreport/"
	sh "rm -rf .scanbuild"
    }

    stage('Package') {
	echo "Packaging.."
	sh "mkdir -p .scanreport; scan-build -k -o .scanbuild -v make devrpm; mv -f \$( find .scanbuild -maxdepth 1 -not -empty -not -name '.scanbuild')/* .scanreport/"
	sh "rm -rf .scanbuild"
    }

    stage('Report') {
	sh "cppcheck_junit cppcheck_results.xml formatted_cpp_results.xml"
	junit "formatted_cpp_results.xml"
	warnings canComputeNew: false, canResolveRelativePaths: false, canRunOnFailed: true, categoriesPattern: '', defaultEncoding: '', excludePattern: '', healthy: ''; includePattern: '', messagesPattern: '', parserConfigurations: [[parserName: 'Pep8', pattern: 'pep8.txt'], [parserName: 'PyLint', pattern: 'pylint.txt']], unHealthy: ''
	sloccountPublish encoding: '', ignoreBuildFailure: true, pattern: 'sloccount.sc'
	publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: '.scanreport', reportFiles: 'index.html', reportName: 'Scan-Build reports', reportTitles: ''])
    }
}
