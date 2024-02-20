# Spot potentially corrupted rules

## Missing Overrides
    
    SELECT
    CASE
      WHEN (cr.origin = 'SYSTEM') THEN CONCAT(cr.link_uuid, '_@_', cr.uuid)
      WHEN (cr.origin = 'OVERRIDE') THEN CONCAT(cr.uuid, '_@_', cr.link_uuid)
      ELSE 'N/A'
    END AS linked_ids,
    COUNT(cr.id)
    FROM custom_rule cr
    LEFT OUTER JOIN custom_rule crx ON (cr.link_uuid = crx.uuid)
    WHERE cr.link_uuid IS NOT NULL
    GROUP BY linked_ids
    HAVING COUNT(cr.id) <> 2
    ORDER BY linked_ids ;

For those that match, get the details, e.g.:

    SELECT
    uuid,
    link_uuid,
    id,
    origin,
    array_to_string(REGEXP_MATCHES(convert_from(rule_data, 'UTF8'), '><name>(.*)</name><notes>'), '') AS rule_name
    FROM custom_rule
    WHERE
       link_uuid IN ('24c93bf1-1b48-4290-b6af-ec3cbb617c23','e367c58c-a82f-4e5b-b22b-4418592e1303','SYSTEM-1217','SYSTEM-1208')
    OR uuid      IN ('24c93bf1-1b48-4290-b6af-ec3cbb617c23','e367c58c-a82f-4e5b-b22b-4418592e1303','SYSTEM-1217','SYSTEM-1208') ;
