# Copyright 2022 - Michael De La Rue
# this file may be distributed either under the Artistic License (version 2 or greater)
# or under the GNU General Public License (version 2.0 or greater) at your choice. 

build-spamgourmet-clone:
	docker build spamgourmet-clone

# list of components: server, web, configuration
# starting top down
.PHONY: sanity_test

SERVICES = captchasrv apache2 exim4

sanity_test: # first check that services are running
	set -e ; \
	for i in $(SERVICES); do \
		systemctl is-active $$i; \
	done

