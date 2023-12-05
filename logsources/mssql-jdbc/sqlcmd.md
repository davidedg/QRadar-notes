On a temporary Linux machine (Ubuntu latest will do fine):

    apt -y install docker.io
    
    docker pull mcr.microsoft.com/mssql-tools
    
    docker run --entrypoint /bin/true --name mssqltools mcr.microsoft.com/mssql-tools
    docker export mssqltools > mssqltools.tar
    
    docker rm mssqltools
    docker rmi mcr.microsoft.com/mssql-tools:latest

Then, transfer the `mssqltools.tar` to QRadar EC and etract it into a new dir:
    
    mkdir mssqltools
    cd mssqltools
    tar xf ../mssqltools.tar

Use it with:

    chroot mssqltools /opt/mssql-tools/bin/sqlcmd -S IP_address -U username -P password
