# Copyright 2022 - Michael De La Rue
# this file may be distributed either under the Artistic License (version 2 or greater)
# or under the GNU General Public License (version 2.0 or greater) at your choice. 

build-spamgourmet-clone:
	docker build spamgourmet-clone

# list of components: server, web, configuration
# starting top down
.PHONY: sanity_test

sanity_test: # first check that services are running
	systemctl status captchasrv apache2 exim4

