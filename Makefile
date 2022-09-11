# Copyright 2022 - Michael De La Rue
# this file may be distributed either under the Artistic License (version 2 or greater)
# or under the GNU General Public License (version 2.0 or greater) at your choice. 

# we export the index to ensure that we match code to be
# committed and not files that might not get committed.
build-spamgourmet-clone:
	git checkout-index -f -a --prefix=spamgourmet-clone/code-export/
	docker build --tag spamgourmet-testenv spamgourmet-clone

test:
	@echo "there are no tests so you can't prove it isn't working"
