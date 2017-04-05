SET search_path = public, pg_catalog;

--
-- Name: geometry_columns; Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON TABLE geometry_columns FROM PUBLIC;
REVOKE ALL ON TABLE geometry_columns FROM MYPGUSER;
GRANT ALL ON TABLE geometry_columns TO MYPGUSER;

--
-- Name: geography_columns; Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON TABLE geography_columns FROM PUBLIC;
REVOKE ALL ON TABLE geography_columns FROM MYPGUSER;
GRANT ALL ON TABLE geography_columns TO MYPGUSER;

--
-- Name: spatial_ref_sys; Type: ACL; Schema: public; Owner: -
--

REVOKE ALL ON TABLE spatial_ref_sys FROM PUBLIC;
REVOKE ALL ON TABLE spatial_ref_sys FROM MYPGUSER;
GRANT ALL ON TABLE spatial_ref_sys TO MYPGUSER;
