CREATE SCHEMA pr_occhab;

CREATE TABLE pr_occhab.t_stations(
  unique_id_sinp_station NOT NULL DEFAULT public.uuid_generate_v4(),
  id_dataset integer NOT NULL,
  
)