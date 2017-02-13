all: centos-pdp

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
