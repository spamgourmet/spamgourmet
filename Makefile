# Copyright 2022 - Michael De La Rue
# this file may be distributed either under the Artistic License (version 2 or greater)
# or under the GNU General Public License (version 2.0 or greater) at your choice. 

# we export the index to ensure that we match code to be
# committed and not files that might not get committed.
docker-test: build-spamgourmet-clone
	docker run -i spamgourmet-testenv /usr/bin/perl -s code/mailhandler/spameater  -extradebug=5 -debugstderr=5 <   test/fixture/reject_wrong_domain.email

build-spamgourmet-clone:
	git checkout-index -f -a --prefix=spamgourmet-clone/code-export/
	docker build --tag spamgourmet-testenv spamgourmet-clone
	@RED='\033[0;31m' ; \
	NC='\033[0m' ; \
	test -z "$$(git status --porcelain)" || ( echo "\n  $${RED}UNCLEAN GIT WORKING DIRECTORY UNCLEAN$${NC} \n"; git status ) 

test:
	@echo "there are no tests so you can't prove it isn't working"
