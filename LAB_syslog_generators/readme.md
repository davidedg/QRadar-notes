# SYSLOG Generators

These scripts might come handy to quickly generate syslog entries at a predefined rate
\
\
This is work in progress...
\
\
Example Syslog PFSense Permit on QRadar:
![Syslog_pfsense](https://github.com/davidedg/QRadar-notes/raw/main/LAB_syslog_generators/syslog_pfsense_example_permit.png)
\
\
Example for creating custom events on a windows machine:

     while ($true){ eventcreate /T ERROR /L APPLICATION /D "TEST EVENT" /ID 1000 ; start-sleep 5 }
