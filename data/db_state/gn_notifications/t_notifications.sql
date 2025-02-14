
CREATE TABLE gn_notifications.t_notifications (
    id_notification integer NOT NULL,
    id_role integer NOT NULL,
    title character varying,
    content text,
    url character varying,
    code_status character varying,
    creation_date timestamp without time zone
);

CREATE SEQUENCE gn_notifications.t_notifications_id_notification_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_notifications.t_notifications_id_notification_seq OWNED BY gn_notifications.t_notifications.id_notification;

ALTER TABLE ONLY gn_notifications.t_notifications
    ADD CONSTRAINT t_notifications_pkey PRIMARY KEY (id_notification);

ALTER TABLE ONLY gn_notifications.t_notifications
    ADD CONSTRAINT t_notifications_id_role_fkey FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role);

