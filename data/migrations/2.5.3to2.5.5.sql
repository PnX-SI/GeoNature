-- Add a field to define if the AF has been published or not --
ALTER TABLE gn_meta.t_acquisition_frameworks ADD is_closed bool NULL DEFAULT false;
ALTER TABLE gn_meta.t_acquisition_frameworks ADD initial_closing_date timestamp NULL;
