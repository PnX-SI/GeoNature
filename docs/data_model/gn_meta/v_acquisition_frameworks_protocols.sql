
\restrict Rd2dYfqMPT1tbSVZkFIYlbAXEJSywZxc9Q9xWGV3v3kGR0gdNXFn6ZI9yNeq1Ix

CREATE VIEW gn_meta.v_acquisition_frameworks_protocols AS
 SELECT d.id_acquisition_framework,
    cdp.id_protocol
   FROM ((gn_meta.t_acquisition_frameworks taf
     JOIN gn_meta.t_datasets d ON ((d.id_acquisition_framework = taf.id_acquisition_framework)))
     JOIN gn_meta.cor_dataset_protocol cdp ON ((cdp.id_dataset = d.id_dataset)));

\unrestrict Rd2dYfqMPT1tbSVZkFIYlbAXEJSywZxc9Q9xWGV3v3kGR0gdNXFn6ZI9yNeq1Ix

