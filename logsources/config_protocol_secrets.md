
SQL Database password:

    echo "
    SELECT
    spcp.value
    FROM
    sensordevice sd
    INNER JOIN sensorprotocolconfigparameters spcp ON (sd.spconfig = spcp.sensorprotocolconfigid)
    WHERE
        sd.id = ID-of-the-Log-Source
    AND spcp.name = 'databasePassword' ;
    " | psql -U qradar -qtA | java -jar /opt/qradar/jars/ibm-si-mks.jar decrypt_command_line
    
