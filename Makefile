# Copyright 2022 - Michael De La Rue
# this file may be distributed either under the Artistic License (version 2 or greater)
# or under the GNU General Public License (version 2.0 or greater) at your choice.

DEV_MOUNT := --volume $(CURDIR):/code-live

.PHONY: help
help: ## list all goals in makefile with brief docmentation
	@echo Call make with one of these make goals: ; echo
	@grep "##" $(MAKEFILE_LIST) | grep -v '\^grep' | sed 's/:[^#]*##/ - /' | sort

.PHONY: all
all: build-spamgourmet-clone test docker-run-test ## standard goal to run which should do all the expected developer things

docker-test: build-spamgourmet-clone docker-run-test
# we export the index to ensure that we match code to be
# committed and not files that might not get committed.
.PHONY: docker-test
docker-test: ## (re)build docker container and run functional tests
	@echo done

.PHONY: docker-run-test
docker-run-test: ## run functional tests only (assumes docker container was already built)
	docker run $(DEV_MOUNT) -i spamgourmet-testenv make -C /code-live full-env-test

.PHONY: docker-run-example
docker-run-example: ## run an example spameater call - N.B. does not update the container
	docker run -i spamgourmet-testenv /usr/bin/perl -s code/mailhandler/spameater  \
		-extradebug=5 -debugstderr=5 <   test/fixture/reject_wrong_domain.email

.PHONY: build-spamgourmet-clone
build-spamgourmet-clone: ## (re)build docker container only - requires network
	git checkout-index -f -a --prefix=spamgourmet-clone/code-export/
	docker build --tag spamgourmet-testenv spamgourmet-clone
	@RED='\033[0;31m' ; \
	NC='\033[0m' ; \
	test -z "$$(git status --porcelain)" \
		|| ( echo "\n  $${RED}UNCLEAN GIT WORKING DIRECTORY UNCLEAN$${NC} \n"; git status )

.PHONY: full-env-test
full-env-test: ## tests which require the full running spamgourmet environment - e.g. integration or functional tests
	./test/test-maileater.sh

.PHONY: shell
shell: ## start interactive shell inside docker container
	docker run $(DEV_MOUNT) -w /code-live -ti spamgourmet-testenv /bin/bash
.PHONY: test
test: ## tests which only require local programming environment - e.g. unit tests
	@echo "there are no tests so you can't prove it isn't working"
