# Fix for "Internal Server Error" on QRadar Analyst Workflow (supposedly bugged version) 2.31.4

Trying out new `/console/ui/` on 7.5(fp2if2), but apparently got unlucky and faced what seems to be a bug with latest (v2.31.4) app version.

Debug crashcourse:

- discover app id
`/opt/qradar/support/recon ps | grep -i analyst`
> ***1308***    QRadar Analyst Workflow         53              apps                    qapp-1308       ++      qapp-1308       +++++   5000    ++++

- docker inspect the app (on all-in-one console or on the relevant app host)

`/opt/qradar/support/recon connect 1308`

- examine app error log

`sh-4.4$ tail -f /opt/app-root/store/log/app.stderr`

>			Error: Default namespace not found at /opt/app-root/app/public/static/locales/en_us/common.json
>				at createConfig (/opt/app-root/app/node_modules/next-i18next/dist/commonjs/config/createConfig.js:165:19)
>				at _callee$ (/opt/app-root/app/node_modules/next-i18next/dist/commonjs/serverSideTranslations.js:201:53)
>				at tryCatch (/opt/app-root/app/node_modules/next-i18next/node_modules/@babel/runtime/helpers/regeneratorRuntime.js:86:17)
>				at Generator._invoke (/opt/app-root/app/node_modules/next-i18next/node_modules/@babel/runtime/helpers/regeneratorRuntime.js:66:24)
>				at Generator.next (/opt/app-root/app/node_modules/next-i18next/node_modules/@babel/runtime/helpers/regeneratorRuntime.js:117:21)
>				at asyncGeneratorStep (/opt/app-root/app/node_modules/next-i18next/node_modules/@babel/runtime/helpers/asyncToGenerator.js:3:24)
>				at _next (/opt/app-root/app/node_modules/next-i18next/node_modules/@babel/runtime/helpers/asyncToGenerator.js:25:9)
>				at processTicksAndRejections (node:internal/process/task_queues:96:5)

- this path (`/opt/app-root/app/public/static/locales/en_us/`) does not exist.

Pretty funny, because this kinda seems loosely related to https://www.ibm.com/support/pages/node/6596983 which I've already met :(

Seems IBM can't make up their minds on how to configure locales, huh ?!

- please the app with a nice and warm symlink:

`ln -sf en /opt/app-root/app/public/static/locales/en_us`

> sh-4.4$ ls -al /opt/app-root/app/public/static/locales/en_us
> 
> lrwxrwxrwx 1 appuser appuser 2 Oct 16 22:22 /opt/app-root/app/public/static/locales/en_us -> en

- Enjoy access to new ui
