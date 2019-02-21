#!/usr/bin/groovy
node("any||$BRANCH_NAME") {
    try {
        if (!env.NOSETESTS_ARGS) {
        env.NOSETESTS_ARGS=" --with-xunit --verbose --process-restartworker --process-timeout=60 --xunit-file=$WORKSPACE/tests/report/nosetests.xml"
        env.NOSETESTS_ARGS="$NOSETESTS_ARGS --with-coverage --cover-inclusive"
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

        def cproject = false
        def cfiles = sh returnStatus : true, script: 'ls packaged/src | grep -P ".*\\.c" '

        if (cfiles == 0) {
        cproject = true
        }
        env.DNAME = sh returnStdout: true, script: '''
        while read l; do
            echo $l | cut -d " " -f 3 | rev | cut -c 3- | rev
        done < deps.make
        '''
        def deps = env.DNAME.trim().split("\n")

        stage('Dependencies') {
        echo "Checking dependencies..."
        //sh "rm -rf archives"
        //env.UPSTREAMS = ""
        //for (ii = 0; ii < deps.size(); ii++) {
        //    env.DNAME = deps[ii]
        //    try {
        //        copyArtifacts filter: "${DNAME}-${BRANCH_NAME}.tar", fingerprintArtifacts: true, projectName: "${DNAME}/${BRANCH_NAME}", selector: lastSuccessful()
        //        env.BRANCH = "${BRANCH_NAME}"
        //    } catch (error) {
        //        sh """
        //            echo "copyArtifacts returned: $error try with branch develop"
        //           """
        //        copyArtifacts filter: "${DNAME}-develop.tar", fingerprintArtifacts: true, projectName: "$DNAME/develop", selector: lastSuccessful()
        //        env.BRANCH = "develop"
        //    }
        //    if (ii != deps.size() -1) {
        //        env.UPSTREAMS = "$UPSTREAMS${DNAME}/${BRANCH},"
        //    } else {
        //        env.UPSTREAMS = "$UPSTREAMS${DNAME}/${BRANCH}"
        //    }
        //    sh '''
        //        tar -xf ${DNAME}-${BRANCH}.tar
        //        '''
        //}
        //sh '''
        //        rm -rf install /tmp/rpmsdb/${JOB_NAME/\\//-}-rpms
        //        mkdir -p  /tmp/rpmsdb
        //        rpm -i --force --nodeps --dbpath /tmp/rpmsdb/${JOB_NAME/\\//-}-rpms --relocate /usr=/$PWD/install/ --relocate /etc=$PWD/install/etc archives/*x86_64.rpm
        //        mkdir -p tests/report/valgrind
        //    '''
        //def UPSTREAMS = env.UPSTREAMS
        echo "Running Sloccount..."

        sh "mkdir -p .slocdata; sloccount --datadir .slocdata --wide --details $WORKSPACE/packaged $WORKSPACE/tests $WORKSPACE/misc > sloccount.sc && echo 'sloccount complete' "
        }

        stage('Build') {
        echo 'Building..'
        sh '''
        sh bootstrap.sh;
        . $WORKSPACE/dependencies.sh install
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

        if (cproject) {
            echo "Running cppcheck"
            sh '''
            echo "*:$PWD/packaged/src/gen-cpp/*" > supp_cppcheck.txt
            cppcheck --enable=all --template="{file},{line},{severity},{id},{message}" --suppressions-list=supp_cppcheck.txt  --std=c99 $WORKSPACE/packaged/src/ $WORKSPACE/packaged/include/ 2> tests/report/cppcheck_results.txt && echo 'cppcheck complete'
            '''
        }
        else {
            echo "Not running cppcheck"
        }

        }

        stage('Test') {
        echo 'Testing..'
        sh '''
        . $WORKSPACE/dependencies.sh install
        make check
        '''
        }


        stage('Package') {
        echo "Packaging.."
        env.ANAME = sh returnStdout: true, script: 'echo ${JOB_NAME/\\//-}'
        env.ANAME = env.ANAME.trim().trim()
        sh '''
        . $WORKSPACE/dependencies.sh install
        make devrpm
        cd $WORKSPACE

        echo $BRANCH_NAME > archives/${ANAME}-GIT_BRANCH
        echo $(git rev-parse --verify HEAD) > archives/${ANAME}-GIT_COMMIT

        tar -cf ${ANAME}_full.tar archives
        rm -f archives/*-gpu*
        tar -cf ${ANAME}.tar archives
        '''
        archiveArtifacts "${ANAME}.tar"
        archiveArtifacts "${ANAME}_full.tar"
        }


        stage('Report') {

        sh "$WORKSPACE/misc/shared/cov_merge.py -o ./tests/report/coverage.xml ./tests/report/py_coverage.xml ./tests/report/c_coverage.xml"
        sh "sed -i \"s#[/.].libs##g\" ./tests/report/coverage.xml"

        if (fileExists("tests/report/cunit-Results.xml")) {
            sh "xsltproc -o tests/report/cunit.xml /usr/share/citools/cunit_to_junit.xsl tests/report/cunit-Results.xml"
            junit "tests/report/cunit.xml"
        }

        def valreport = sh script: 'ls tests/report/valgrind | grep -P ".*\\.xml" ', returnStatus: true

        if (valreport == 0) {
            publishValgrind (
                             failBuildOnInvalidReports: false,
                             failBuildOnMissingReports: false,
                             failThresholdDefinitelyLost: '',
                             failThresholdInvalidReadWrite: '',
                             failThresholdTotal: '',
                             pattern: '**/tests/report/valgrind/*',
                             publishResultsForAbortedBuilds: false,
                             publishResultsForFailedBuilds: false,
                             sourceSubstitutionPaths: '',
                             unstableThresholdDefinitelyLost: '',
                             unstableThresholdInvalidReadWrite: '',
                             unstableThresholdTotal: ''
                            )
        }

        if (fileExists("tests/report/coverage.xml")) {
            cobertura autoUpdateHealth: false, autoUpdateStability: false, coberturaReportFile: "**/tests/report/coverage.xml", conditionalCoverageTargets: '70, 0, 0', failNoReports: false, failUnhealthy: false, failUnstable: false, lineCoverageTargets: '80, 0, 0', maxNumberOfBuilds: 0, methodCoverageTargets: '80, 0, 0', onlyStable: false
        }

        warnings(
            canComputeNew: false,
            canResolveRelativePaths: false,
            canRunOnFailed: true,
            categoriesPattern: '',
            defaultEncoding: '',
            excludePattern: '',
            healthy: '100',
            includePattern: '',
            messagesPattern: '',
            parserConfigurations: [[parserName: 'cppcheck', pattern: '**/tests/report/cppcheck_results.txt'] ],
            unHealthy: ''
            )

        sloccountPublish( encoding: '',
                          ignoreBuildFailure: true,
                          pattern: 'sloccount.sc')

        if (cproject) {
            try {
                publishHTML([allowMissing: true, alwaysLinkToLastBuild: false, keepAll: false, reportDir: '.scanreport', reportFiles: 'index.html', reportName: 'Scan-Build reports', reportTitles: ''])
            }
            catch (err) {
                echo "Failed to publish scan reports"
            }
        }

        publishHTML([allowMissing: true, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'packaged/doc/html', reportFiles: 'index.html', reportName: 'Doxygen reports', reportTitles: ''])

        }
    }
    catch (err) {
        currentBuild.result = "FAILURE"
		emailext body: "${BUILD_TAG} failed, please go to Jenkins and verify the build", recipientProviders: [[$class: 'CulpritsRecipientProvider']], subject: "${BUILD_TAG} FAILED"
    }
}
properties([
           disableConcurrentBuilds(),
           //pipelineTriggers([
           //                 triggers: [
           //                 [
           //                 $class: 'jenkins.triggers.ReverseBuildTrigger',
           //                 upstreamProjects: UPSTREAMS, threshold: hudson.model.Result.SUCCESS
           //                 ]
           //                 ]
           //]),
    [$class: 'BuildDiscarderProperty', strategy: [$class: 'LogRotator', artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '30']],
])
