"""
    methodes pour ref_geo
        - recupération du srid local
"""


def get_local_srid(bind):
    """
    permet de récupérer le srid local ( celui de ref_geo.l_areras.geom)
    """
    return bind.execute("SELECT FIND_SRID('ref_geo', 'l_areas', 'geom')").scalar()
