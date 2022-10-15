-----------------------------------------------------------------------------------------------------
-- CREATE A NEW INTERFACE FLOW FROM SQL
-- workaround for missing interface list in with QRadar 7.5+ on my home lab

-- !!! ensure there are no pending deploy !!!

-- check current values
SELECT * FROM flowsource;
select * from flowsource_sequence;
SELECT * FROM flowsource_config;
select * from flowsourceconfig_sequence;
SELECT * FROM flowsource_config_parameters;
select * from flowsource_config_parameters_sequence;
SELECT * FROM flowsource_lookup;


-- create config

INSERT INTO flowsource_config (
  id, flowsource_type_id, config_name
) (
  SELECT 
    nextval('flowsourceconfig_sequence') AS id, 
    0 AS flowsource_type_id, 
    'NIC_null' AS config_name
) RETURNING id AS new_flowsource_config;


-- create config parameters

-- specify a capture filter if needed

INSERT INTO flowsource_config_parameters (
  name,flowsource_config_id, value, id
) (
  SELECT
    'SV_FILTER' AS name,
	(SELECT max(id) FROM flowsource_config) AS flowsource_config_id,
	'' AS value, -- insert your bpf filter here
	nextval('flowsource_config_parameters_sequence') AS id
) RETURNING id AS new_flowsource_config_parameters__base;

-- specify network interface name

INSERT INTO flowsource_config_parameters (
  name,flowsource_config_id, value, id
) (
  SELECT
    'DEVICE' AS name,
	(SELECT max(id) FROM flowsource_config) AS flowsource_config_id,
	'ens33' AS value, -- insert your network interface name here
	(1+(SELECT max(id) FROM flowsource_config_parameters)) AS id
) RETURNING id AS new_flowsource_config_parameters__current;


-- create the flow source

INSERT INTO flowsource (
  id,name,enabled,deployed,asymmetrical,target_qflow_id,flowsource_type_id,flowsource_config_id
) (
    SELECT
	  nextval('flowsource_sequence') AS id,
	  'qcapture0' AS name, -- insert your flow source name here
	  't',
	  'f',
	  'f',
	  3,	-- see the correct value from existing ones.... I dunno where to fetch it from :(
	  0,	
	 (SELECT max(id) FROM flowsource_config) AS flowsource_config_id
) RETURNING id AS new_flowsource;



-- this gets populated later, on deploy
-- INSERT INTO flowsource_lookup (
--   id, sensor_name, interface_name, domain_id
-- )	  


-- notify a deploy is required for qflow components
UPDATE deployed_component SET changed = 't' WHERE name = 'qflow0';

--- show servers - note id of modified server
select id,ip,hostname,managed_host_id from serverhost;

--- update modified timestamp on server !!! replace id with your server id !!!
UPDATE ServerHost SET updateDate=q.ts FROM ( SELECT date_trunc('milliseconds', TIMESTAMP 'NOW') AS ts ) AS q WHERE id=51 ;



-- check values again after deploy:
SELECT * FROM flowsource;
select * from flowsource_sequence;
SELECT * FROM flowsource_config;
select * from flowsourceconfig_sequence;
SELECT * FROM flowsource_config_parameters;
select * from flowsource_config_parameters_sequence;
SELECT * FROM flowsource_lookup;

