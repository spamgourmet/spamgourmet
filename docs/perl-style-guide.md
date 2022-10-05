Spamgourmet contains a bunch of old Perl code written in a different era when
Perl was very much an experimental lingua-franca of new web services.

We are aiming to gradually improve that code to make it more
maintainable without breaking things.

Database Queries
################

Currently database queries are all done as hand-coded SQL with prepared
queries. Any deviation from this, for example introducing an ORM system, must be
done with care because the database query rate is one of the key efficiency
factors for Spamgourmet.

Use of libraries
################

Use of standard Perl libraries included in the Perl distribution is encouraged.

Use of other libraries needs to be considered with some care to ensure
maintainability. Many Perl modules which used to be great seem to have lost
their maintainers.

Using a library is normally better for maintenance than rolling our own code,
however please look through our discussion about libraries and if you want to
use a new one, please mention it there, preferably after making some
investigation to see if the library is still accepting bug fixes.

https://github.com/spamgourmet/spamgourmet/issues/44
