
-- Delete rules with certain names
DELETE FROM custom_rule where rule_data like '%<name>BB:HostDefinition: VA Scanner Source IP</name>%' and origin = 'OVERRIDE';


-- Find rules with matching link_uuid
SELECT id,origin,uuid,link_uuid from custom_rule cr
where (select id from custom_rule cri where cri.link_uuid <> '' AND cri.link_uuid = cr.uuid) > 1 ;


-- Find rules with orphaned link_uuid (these may be converted to SYSTEM type if a corresponding OVERRIDE rule is present)
SELECT id,uuid,link_uuid FROM custom_rule where origin = 'USER' AND link_uuid IS NOT NULL;


-- Break link_uuid relationship
UPDATE custom_rule SET link_uuid = NULL;


--------------------------------------------------------------------------------------------------------------------------
-- Export Rules in CSV files
\COPY (SELECT * FROM custom_rule) TO 'custom_rules.csv'  WITH DELIMITER ';' CSV HEADER;
\COPY (SELECT * FROM custom_rule where origin = 'USER') TO 'custom_rules_user.csv'  WITH DELIMITER ';' CSV HEADER;
\COPY (SELECT * FROM custom_rule where origin = 'OVERRIDE') TO 'custom_rules_override.csv'  WITH DELIMITER ';' CSV HEADER;
\COPY (SELECT * FROM custom_rule where origin = 'SYSTEM') TO 'custom_rules_system.csv'  WITH DELIMITER ';' CSV HEADER;

-- Create a table to hold imported rules to selectively copy from 
CREATE TABLE custom_rule_import AS SELECT * FROM custom_rule LIMIT 0;

-- Import CSV into import table
\COPY custom_rule_import  FROM 'custom_rules.csv' with DELIMITER ';' CSV HEADER;

-- Empty rules db:
DELETE FROM custom_rule;

-- Selectively import back rules
-- e.g. only first 50, not-overridden SYSTEM rules, excluding rule_type 4 and with title beginning with "BB:" and n
INSERT INTO custom_rule (SELECT * FROM custom_rule_import WHERE 
      origin='SYSTEM'
  AND link_uuid IS NULL
  AND rule_type <> 4
  AND rule_data like '%<name>BB:%</name>%'
  order by id asc
  limit 50
) ON CONFLICT (id) DO NOTHING;

--------------------------------------------------------------------------------------------------------------------------

