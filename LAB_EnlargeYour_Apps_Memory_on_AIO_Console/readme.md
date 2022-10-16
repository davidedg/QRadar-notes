# Enlarge Your ... App Memory Allocation!

By default, AIO Console only allows for 10% of total physical ram to be allocated to Apps.
The official (and correct) way to do this is to provision a dedicated App Host.

But you wanna try out all those juicy QRadar Apps on your lab environment and you're poor like me and do not own loads of ram... right?
Well, this LAB trick is for you ;P

Edit `/store/configservices/staging/globalconfig/nva.conf` and change/add:

`APP_CONSOLE_MEMORY_PERCENT=15` Or whatever percentage you might dare to try (I tried 25 on a 22GB VM, so far so good).

![More RAM!!](https://github.com/davidedg/QRadar-notes/raw/main/LAB_EnlargeYour_Apps_Memory_on_AIO_Console/squeezing_apps_ram.PNG)
