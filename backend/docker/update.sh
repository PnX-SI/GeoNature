#!/bin/bash

set -e


# Install / upgrade database
geonature db upgrade geonature@head -x local-srid=2154
geonature db autoupgrade

# Insert TaxRef v15 data if no data
geonature db exec "DO 'BEGIN ASSERT EXISTS (SELECT 1 FROM taxonomie.taxref); END'" 2>/dev/null || geonature taxref import-v15 --skip-bdc-statuts
