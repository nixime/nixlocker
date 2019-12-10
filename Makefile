#
# Copyright 2019 NIXIME@GITHUB
#

BUILD_NUM=1
VERSION=1.1.0

all:nixlocker-rpm

nixlocker-rpm:
	rpmdev-setuptree
	tar \
		--exclude='README.md' \
		--exclude='nixlocker.spec' \
		--exclude='Makefile' \
		--exclude='.git' \
		--exclude='.project' \
		-zcvf ~/rpmbuild/SOURCES/nixlocker.tgz .
		
	cp nixlocker.spec ~/rpmbuild/SPECS

	rm -f ~/rpmbuild/RPMS/x86_64/nixlocker-*.rpm

	rpmbuild \
		--define '_iv_pkg_version ${BUILD_NUM}' \
		--define '_iv_pkg_release ${VERSION}' \
		-bs ~/rpmbuild/SPECS/nixlocker.spec

	rpmbuild \
		--define '_iv_pkg_version ${BUILD_NUM}' \
		--define '_iv_pkg_release ${VERSION}' \
		--rebuild ~/rpmbuild/SRPMS/nixlocker*.src.rpm

	#rpm --addsign ~/rpmbuild/RPMS/x86_64/nixlocker-*.rpm
