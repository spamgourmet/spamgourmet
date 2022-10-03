Make
####

We're currently using GNU Make as the primary tool for builds. We're
using it as a fairly unsophisticated driver for directory specific
scripts.

If you run just plain

    make

you should see a list of goals that you can run, for example

    make build-spamgourmet-clone

to build the docker container or

    make all

to run the standard set of goals expected during development. If you
have a container build then

    make shell

should get you a shell inside a docker container with all of
spamgourmet set up and with all of the spamgourmet code visible to
allow you to test code you are working on.

GitHub setup
############

Spamgourmet uses GitHub actions to run builds. Control for this is in
.github/workflows in several files. These then call the main Makefile
in every case. This is done to ensure that it is possible to run
everything independently of GitHub.

You can find the triggers for github in YML files in 

.github/workflows/

In order to maintain portability, the actions should not do anything
complex but instead should call out to our Makefiles which should all
required work.


Docker Setup
############

Currently we are (ab)using docker to match the standard spamgourmet
configuration. In other words, instead of multiple well defined docker
images with different functions we have one image with all the code.

The build definitions are all inside the

  spamgourmet-clone

directory and match the way that a normal spamgourmet install would be
built. All of this has the benefit of giving developers direct access
to an environemtn that matches approximately production and allows
testing.

If we change the way spamgourmet is deployed we expect this to change.


TESTS
#####

One of the most important areas for development now for spamgourmet is
increasing our set of tests. We have new developers who aren't yet so
knowledgable about how stuff works and the tests help them to
understand as well as checking that they don't break things.

Currently we have shell based tests. These are driven by shunit2

https://github.com/kward/shunit2

the main test script does various setup and so on, including calling a
perl script to create testing data

`test/create-test-user.pl` is the script used for creating user
data. If you want to ad a new test you probably have to both add the
test and add functions called from this script to create data for your
test.