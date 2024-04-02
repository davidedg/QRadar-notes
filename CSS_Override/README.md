# CSS Override for the Top Navigation header

If you manage many QRadar environments, you might want a way to easily distinguish them.
\
For exmaple, by using a different color for the Top Navigation Layout:

\
![qradar_green_navigation_header](./qradar_green_navigation_header.png)

\
In Firefox, goto `about:config`
\
change `toolkit.legacyUserProfileCustomizations.stylesheets` to `true`
\
\
Then, go to `about:support`
\
click the `Open Folder` button next to the `Profile Folder` option.
\
\
In the profile directory, create a sub-dir named `chrome`.
\
Then a file therein named `userContent.css`
\
\
In this file, you can declare the CSS overrides for the sites that you desire, for example:

    @-moz-document
    domain(192.168.0.190),
    domain(10.150.180.77)
    {
    #topNavLayout {
      background-color: #48ba48 !important;
    }

\
Note: the `!important` directive is required.

\
Restart Firefox for the changes to take effect.
