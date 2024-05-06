Compress Ariel tenant events inline
-----------------------------------

Script to compress each Ariel daily directory into a separate archive, in the same directory.
\
Configure these variables before running it: `TENANT_ID` `GREP_INCLUDE` `GREP_EXCLUDE`
\
Example results:

    aux
     |-> 1
     | |-> 2024
     | | |-> 2
     | | | |-> 28.tar.gz
     | | |-> 3
     | | | |-> 28.tar.gz
     | | | |-> 29.tar.gz
     | | |-> 4
     | | | |-> 2.tar.gz
     | | | |-> 3.tar.gz
     | | | |-> 4.tar.gz
     | | | |-> 5.tar.gz
     | | | |-> 6.tar.gz
     | | | |-> 7.tar.gz
     ...
     | | |-> 5
     | | | |-> 1.tar.gz
     | | | |-> 2.tar.gz
     | | | |-> 3.tar.gz
     | | | |-> 4.tar.gz
     | | | |-> 5.tar.gz
     ...

Use ![uncompress-tenant-data-inline.bash](./uncompress-tenant-data-inline.bash) to uncompress the data back in place.
