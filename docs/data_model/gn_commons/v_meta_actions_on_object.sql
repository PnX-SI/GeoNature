

CREATE VIEW gn_commons.v_meta_actions_on_object AS
 WITH insert_a AS (
         SELECT t_history_actions.id_history_action,
            t_history_actions.id_table_location,
            t_history_actions.uuid_attached_row,
            t_history_actions.operation_type,
            t_history_actions.operation_date,
            ((t_history_actions.table_content ->> 'id_digitiser'::text))::integer AS id_creator
           FROM gn_commons.t_history_actions
          WHERE (t_history_actions.operation_type = 'I'::bpchar)
        ), delete_a AS (
         SELECT t_history_actions.id_history_action,
            t_history_actions.id_table_location,
            t_history_actions.uuid_attached_row,
            t_history_actions.operation_type,
            t_history_actions.operation_date
           FROM gn_commons.t_history_actions
          WHERE (t_history_actions.operation_type = 'D'::bpchar)
        ), last_update_a AS (
         SELECT DISTINCT ON (t_history_actions.uuid_attached_row) t_history_actions.id_history_action,
            t_history_actions.id_table_location,
            t_history_actions.uuid_attached_row,
            t_history_actions.operation_type,
            t_history_actions.operation_date
           FROM gn_commons.t_history_actions
          WHERE (t_history_actions.operation_type = 'U'::bpchar)
          ORDER BY t_history_actions.uuid_attached_row, t_history_actions.operation_date DESC
        )
 SELECT i.id_table_location,
    i.uuid_attached_row,
    i.operation_date AS meta_create_date,
    i.id_creator,
    u.operation_date AS meta_update_date,
    d.operation_date AS meta_delete_date
   FROM ((insert_a i
     LEFT JOIN last_update_a u ON ((i.uuid_attached_row = u.uuid_attached_row)))
     LEFT JOIN delete_a d ON ((i.uuid_attached_row = d.uuid_attached_row)));


