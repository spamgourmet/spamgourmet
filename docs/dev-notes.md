# Make

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
have a container built then

    make shell

should get you a shell inside a docker container with all of
spamgourmet set up and with all of the spamgourmet code visible to
allow you to test code you are working on.

Git and Git Branching
#####################

We use Git as our source code repository management system. This is
quite powerful and sophisticated and so sometimes a little
intimidating to start with. Despite that, what you need to contribute
to spamgourmet will be quite simple. If you don't know git then the
[git getting started
documentation](https://docs.github.com/en/get-started/using-git) is
likely a good place to start:

> [https://docs.github.com/en/get-started/using-git](https://docs.github.com/en/get-started/using-git)

For any changes you make, please fork your repository and create a new
branch named starting with your initials and a description of what
will be in that branch.

When merging code please `git rebase` all of your changes from the latest
version of our development branch just before committing. If you are merging to
the develpment branch for yourself then please use `git merge --no-ff` to create
exactly one empty merge commit with full documentation of the aim of the overall
aim of the changes for a feature branch merge.

For further discussion please see [the discussion in issue 45 in our bug tracker](https://github.com/spamgourmet/spamgourmet/issues/45).

GitHub setup
############

Spamgourmet uses GitHub actions to run builds. Control for this is in
`.github/workflows` in several files. These then call the main Makefile
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
to an environment that matches approximately production and allows
testing.

If we change the way spamgourmet is deployed we expect this to change.

## TESTS

One of the most important areas for development now for spamgourmet is
increasing our set of tests. We have new developers who aren't yet so
knowledgable about how stuff works and the tests help them to
understand as well as checking that they don't break things.

Currently we have shell based tests. These are driven by [the shunit2
unit testing framework](https://github.com/kward/shunit2).

The main test script does various setup and so on, including calling a
perl script to create testing data

`test/create-test-user.pl` is the script used for creating user
data. If you want to ad a new test you probably have to both add the
test and add functions called from this script to create data for your
test.

To run tests

    make docker-test

should rebuild and run the tests or the rebuild can be avoided with

    make docker-run-test

Opinionated Formatting and Static Code Checking
###############################################

We use opinionated formatting and some static code quality
checks. These run in GitHub and in order for a patch to be accepted
into spamgourmet we'll need to get them to pass.

For making a tiny, obvious change it's probably easiest to make the
change and submit a patch. Watch the feedback after the build process
and fix any problems that are reported until the build passes.

If you are going to do more than a couple of lines of changes then
please set up the configuration locally to give you warnings before
committing your code to git.

1. get a python install on your system including pip
2. install pre-commit - <https://pre-commit.com/#install>
3. run `pre-commit install`
