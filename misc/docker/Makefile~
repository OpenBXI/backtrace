all: bxibase-docker

bxibase-docker: bxibase
	echo "Building bxibase-docker"
	docker rm -f bxibase || /bin/true
	docker run  --name bxibase --publish 8080:80 --detach --volume ${PWD}/../articles:/srv local/centos-bxibase

bxibase: jupyter-c
	echo "Building bxibase"
	cp Dockerfile.centos-bxibase /tmp/rpms
	docker build --tag local/centos-bxibase \
		     --rm=true \
		     --file /tmp/rpms/Dockerfile.centos-bxibase \
		     --build-arg HTTP_PROXY=$(http_proxy)\
		     --build-arg HTTPS_PROXY=${https_proxy}\
		     --build-arg FTP_PROXY=${ftp_proxy}\
		     --build-arg NO_PROXY=${no_proxy}\
		     /tmp/rpms

jupyter-c: jupyter
	echo "Building jupyter-c"
	docker build --tag local/centos-jupyter-c \
		     --rm=true \
		     --file Dockerfile.centos-jupyter-c \
		     --build-arg HTTP_PROXY=$(http_proxy)\
		     --build-arg HTTPS_PROXY=${https_proxy}\
		     --build-arg FTP_PROXY=${ftp_proxy}\
		     --build-arg NO_PROXY=${no_proxy}\
		     ${PWD}

jupyter: centos-epel
	echo "Building jupyter"
	docker build --tag local/centos-jupyter \
		     --rm=true \
		     --file Dockerfile.centos-jupyter \
		     --build-arg HTTP_PROXY=$(http_proxy)\
		     --build-arg HTTPS_PROXY=${https_proxy}\
		     --build-arg FTP_PROXY=${ftp_proxy}\
		     --build-arg NO_PROXY=${no_proxy}\
		    ${PWD}

centos-pdp: centos-epel
	echo "Building centos-pdp"
	docker build --tag local/centos-pdp \
		     --rm=true \
		     --file Dockerfile.centos-pdp \
		     --build-arg HTTP_PROXY=$(http_proxy)\
		     --build-arg HTTPS_PROXY=${https_proxy}\
		     --build-arg FTP_PROXY=${ftp_proxy}\
		     --build-arg NO_PROXY=${no_proxy}\
		     ${PWD}


centos-epel:
	echo "Building centos-epel"
	docker build --tag local/centos-epel \
		     --rm=true \
		     --file Dockerfile.centos-epel \
		     --build-arg HTTP_PROXY=$(http_proxy)\
		     --build-arg HTTPS_PROXY=${https_proxy}\
		     --build-arg FTP_PROXY=${ftp_proxy}\
		     --build-arg NO_PROXY=${no_proxy}\
		     ${PWD}
