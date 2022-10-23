# Static Code Checks

In order to make it maximally easy to work on spamgourmet we are using static
code checking and opinionated formatting. The primary tool of choice for this is
`pre-commit` which allows us to run all of the static checks both just before
committing in git, manually over all the files on demand and also in our
automate builds system (currently GitHub actions)

Line Width handling
###################

Our agreed policy on line widths is approximately:

- aim for lines less than 80 characters wide in English text
  (e.g. documentation)
- aim for lines less than 100 characters wide in code
- do not exceed 115 characters wide unless forced to - prefer to break lines
  when reaching this limit.

This leads, however, to us using the default setting in, for example, prettier,
since a target of 80 characters wide will sometimes lead to considerably wider
lines.

Pre-Commit
##########

Learn about pre-commit at <https://pre-commit.com/>

There are two configuration files used to drive pre-commit

- .pre-commit-config.yaml - used locally, this is the recommended set of checks

- .pre-commit-config-build.yaml - used during automated builds - this is the set
  of checks that will actually fail patches

Disabled checks in the build currwently include perlcritic. As an exception, if
working on an old perl file then it is acceptable to bypass this check. First
attempt the commit and get any formatting fixes. Add those fixes to the commit,
then you can reun `git commit --no-verify` to bypass the code checks for this
particular commit. Please consider fixing the file instead.

Perl code
#########

We currently use perltidy as the primarly system for formatting perl. Chosen
over prettier since perl is currently the main langauge in the code and this is
the standard perl tool.

We use perlcritic to get commentary on perl code. This is currently not enforced
in the build. See pre-commit above for more details
