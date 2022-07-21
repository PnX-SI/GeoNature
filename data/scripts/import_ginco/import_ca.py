""" 
	Script importing metadata in GeoNature DataBase based on uuid of datasets to import
	Use the inpn webservice to get corresponding xml files. Works with datasets and acquisition frameworks, not yet with parents acquisition frameworks (to do)
"""
import os
import datetime
import xml.etree.ElementTree as ET

import requests
import psycopg2


"""
CONFIG
"""
SQLALCHEMY_DATABASE_URI = "postgresql://{user}:{password}@{host}:{port}/{database}".format(
    user=os.environ["geonature_pg_user"],
    password=os.environ["geonature_user_pg_pass"],
    host=os.environ["db_host"],
    port=os.environ["db_port"],
    database=os.environ["geonature_db_name"],
)
TABLE_DONNEES_INPN = os.environ["TABLE_DONNEES_INPN"]
CHAMP_ID_JDD = os.environ["CHAMP_ID_JDD"]
DELETE_XML_FILE_AFTER_IMPORT = os.environ["DELETE_XML_FILE_AFTER_IMPORT"]


# Connecting to DB and openning a cursor
try:
    conn = psycopg2.connect(SQLALCHEMY_DATABASE_URI)
except Exception as e:
    print("Connexion à la base impossible")

cursor = conn.cursor()


"""
Constants
"""

# Namespaces for metadata XML files
xml_namespaces = {
    "gml": "http://www.opengis.net/gml/3.2",
    "ca": "http://inpn.mnhn.fr/mtd",
    "jdd": "http://inpn.mnhn.fr/mtd",
    "xlink": "http://www.w3.org/1999/xlink",
    "xsi": "http://www.w3.org/2001/XMLSchema-instance",
}

# Paths to different king of informations in XML files
af_main = "gml:featureMember/ca:CadreAcquisition/ca:"
af_temp_ref = "gml:featureMember/ca:CadreAcquisition/ca:ReferenceTemporelle/ca:"
af_main_actor = "gml:featureMember/ca:CadreAcquisition/ca:acteurPrincipal/ca:ActeurType/ca:"
ds_main = "gml:featureMember/jdd:JeuDeDonnees/jdd:"
ds_bbox = "gml:featureMember/jdd:JeuDeDonnees/jdd:empriseGeographique/jdd:BoundingBox/jdd:"
ds_contact_pf = "gml:featureMember/jdd:JeuDeDonnees/jdd:pointContactPF/jdd:ActeurType/jdd:"

"""
Parsing functions
	3 distinct functions used to get 3 kinds of data, parsing XML Files : 
		- single data under file root or non-repeatable node, (dataset and acquisition framework name, bbox...)
		- tuple data under file root, (territories, keywords...)
		- single data under repeatable nodes, themself under file root (publications, actors...)
"""


def get_single_data(node, path, tag):
    # path = af_main & tags = ['identifiantCadre','libelle','description','estMetaCadre','typeFinancement','niveauTerritorial','precisionGeographique','cibleEcologiqueOuGeologique','descriptionCible','dateCreationMtd','dateMiseAJourMtd']
    # path = af_temp_ref & tags = ['dateLancement','dateCloture']
    # path = af_main_actor & tags = ['mail','nomPrenom','roleActeur','organisme','idOrganisme']
    # path = ds_main & tags = ['identifiantJdd','identifiantCadre','libelle','libelleCourt','description','typeDonnees','objectifJdd','domaineMarin','domaineTerrestre','dateCreation','dateRevision']
    # path = ds_bbox & tags = ['borneNord','borneSud','borneEst','borneOuest']
    # path = ds_contact_pf & tags = ['mail','nomPrenom','roleActeur','organisme','idOrganisme']
    try:
        data = node.find(path + tag, namespaces=xml_namespaces).text
        if data != None:
            return data
        else:
            return ""
    except Exception as e:
        return ""


def get_tuple_data(node, path, tag):
    # path = af_main & tags = ['motCle','objectifCadre','voletSINP','territoire']
    # path = ds_main & tags = ['motCle','territoire']
    data = []
    try:
        datas = CURRENT_XML.findall(path + tag, namespaces=xml_namespaces)
        if datas == []:
            return ""
        else:
            for row in datas:
                data.append(str(row.text))
            return data
    except Exception as e:
        return ""


def get_inner_data(object, iter, tag):
    # Object = af_publications, iter = cur_publi, tags = ['referencePublication','URLPublication']
    # Object = ds_protocols, iter = cur_proto, tags = ['libelleProtocole','descriptionProtocole','url']
    # Object = ds_pointscontacts, iter = point_contact,
    # Object = af_othersactors, iter = other_actor, tags = ['nomPrenom', 'mail', 'roleActeur', 'organisme', 'idOrganisme']
    try:
        cur_data = object[iter].find("ca:" + tag, xml_namespaces).text
        if cur_data != "":
            return cur_data
        else:
            return ""
    except Exception as e:
        return ""


"""
Datatype protocols 
	Only protocols with a name are considered. Protocol name is the reference used as "key" for import
	WARNING : on 490 tested datasets, no one had protocol name stored in xml files. So, no protocols have been created... (only url most of time)
"""

"""
Acquisition frameworks
"""

# Check existing to avoid duplicates
def get_known_af():
    cursor.execute(
        "SELECT DISTINCT unique_acquisition_framework_id FROM gn_meta.t_acquisition_frameworks"
    )
    results = cursor.fetchall()
    return [r[0].upper() for r in results]


def insert_update_t_acquisition_frameworks(CURRENT_AF_ROOT, action, cur_af_uuid):
    identifiantCadre = cur_af_uuid
    libelle = get_single_data(CURRENT_AF_ROOT, af_main, "libelle")
    description = get_single_data(CURRENT_AF_ROOT, af_main, "description")

    # dateLancement : DEFAULT='01/01/1800'
    if get_single_data(CURRENT_AF_ROOT, af_temp_ref, "dateLancement") == "":
        dateLancement = datetime.datetime.now()
    else:
        dateLancement = get_single_data(CURRENT_AF_ROOT, af_temp_ref, "dateLancement")
    # dateCreationMtd
    if get_single_data(CURRENT_AF_ROOT, af_main, "dateCreationMtd") == "":
        dateCreationMtd = datetime.datetime.now()
    else:
        dateCreationMtd = get_single_data(CURRENT_AF_ROOT, af_main, "dateCreationMtd")
    # dateMiseAJourMtd
    if get_single_data(CURRENT_AF_ROOT, af_main, "dateMiseAJourMtd") == "":
        dateMiseAJourMtd = datetime.datetime.now()
    else:
        dateMiseAJourMtd = get_single_data(CURRENT_AF_ROOT, af_main, "dateMiseAJourMtd")
    # dateCloture
    if get_single_data(CURRENT_AF_ROOT, af_temp_ref, "dateCloture") == "":
        dateCloture = datetime.datetime.now()
    else:
        dateCloture = get_single_data(CURRENT_AF_ROOT, af_temp_ref, "dateCloture")
    # Write and run query
    if action == "create":
        cur_query = """
			INSERT INTO gn_meta.t_acquisition_frameworks(
			unique_acquisition_framework_id, 
			acquisition_framework_name, 
			acquisition_framework_desc, 
			acquisition_framework_start_date, 
			acquisition_framework_end_date, 
			meta_create_date, 
			meta_update_date,
			opened
		)
		VALUES (
		%s , 
		%s ,
		%s , 
		%s , 
		%s ,
		%s , 
		%s ,
        %s
		) RETURNING id_acquisition_framework;
		"""
        result = "New acquisition framework created..."
        cursor.execute(
            cur_query,
            (
                identifiantCadre,
                libelle[0:254],
                description,
                dateLancement,
                dateCloture,
                dateCreationMtd,
                dateMiseAJourMtd,
                False,
            ),
        )
    elif action == "update":
        cur_query = """
			UPDATE gn_meta.t_acquisition_frameworks SET 
				acquisition_framework_name= %s, 
				acquisition_framework_desc= %s, 
				acquisition_framework_start_date= %s, 
				acquisition_framework_end_date= %s,
				meta_create_date= %s, 
				meta_update_date= %s,
				opened= %s
				WHERE unique_acquisition_framework_id= %s
				RETURNING id_acquisition_framework;
		"""
        result = "Existing acquisition framework updated..."
        cursor.execute(
            cur_query,
            (
                identifiantCadre,
                libelle[0:254],
                description,
                dateLancement,
                dateCloture,
                dateCreationMtd,
                dateMiseAJourMtd,
                False,
                cur_af_uuid,
            ),
        )
    r = cursor.fetchone()
    created_or_returned_id = None
    if r:
        created_or_returned_id = r[0]
    conn.commit()
    return created_or_returned_id


"""
	Datasets 
"""


def get_known_ds():
    cursor.execute("SELECT DISTINCT unique_dataset_id FROM gn_meta.t_datasets")
    results = str(cursor.fetchall())
    known = (
        results.replace("(", "")
        .replace(")", "")
        .replace("[", "")
        .replace("]", "")
        .replace(",", "")
        .replace("'", "")
        .split(" ")
    )
    return known


""" 
	Getting XML Files & pushing Acquisition Frameworks data in GeoNature DataBase
"""


def insert_CA(cur_af_uuid):
    """
    insert a CA and return the created ID
    """
    if cur_af_uuid[1:-1] in get_known_af():
        action = "update"
    else:
        action = "create"
    # Get and parse corresponding XML File
    # remove ''
    cur_af_uuid = cur_af_uuid.upper()
    af_URL = "https://inpn.mnhn.fr/mtd/cadre/export/xml/GetRecordById?id={}".format(cur_af_uuid)
    request = requests.get(af_URL)
    if request.status_code == 200:
        open("{}.xml".format(cur_af_uuid), "wb").write(request.content)
        CURRENT_AF_ROOT = ET.parse("{}.xml".format(cur_af_uuid)).getroot()
        # Feed t_acquisition_frameworks
        af_id = insert_update_t_acquisition_frameworks(CURRENT_AF_ROOT, action, cur_af_uuid)
        # Feed cor_acquisition_framework_voletsinp

        # Delete files if choosen
        if DELETE_XML_FILE_AFTER_IMPORT == "True":
            os.remove("{}.xml".format(cur_af_uuid))
        return af_id
    else:
        print("CA NOT FOUND: " + cur_af_uuid)
        return None


# Parse and import data in GeoNature database

"""
	Getting XML Files & pushing Datasets data in GeoNature DataBase
"""
# Getting uuid list of JDD to import

q = "SELECT id_acquisition_framework FROM gn_meta.t_acquisition_frameworks WHERE acquisition_framework_name ILIKE 'CA provisoire - import Ginco -> GeoNature'"
cursor.execute(q)
old_id_af = cursor.fetchone()[0]


cursor.execute(
    "SELECT unique_dataset_id FROM gn_meta.t_datasets WHERE id_acquisition_framework ="
    + str(old_id_af)
)
ds_uuid_list = cursor.fetchall()


for ds_iter in range(len(ds_uuid_list)):
    cur_ds_uuid = ds_uuid_list[ds_iter][0]
    if cur_ds_uuid not in get_known_ds():
        action = "create"
    else:
        action = "update"
    # Get and parse corresponding XML File
    ds_URL = "https://inpn.mnhn.fr/mtd/cadre/jdd/export/xml/GetRecordById?id={}".format(
        cur_ds_uuid.upper()
    )
    req = requests.get(ds_URL)
    if req.status_code == 200:
        print(cur_ds_uuid + " found")
        open("{}.xml".format(cur_ds_uuid), "wb").write(requests.get(ds_URL).content)
        CURRENT_DS_ROOT = ET.parse("{}.xml".format(cur_ds_uuid)).getroot()
        # insertion des CA
        current_af_uuid = get_single_data(CURRENT_DS_ROOT, ds_main, "identifiantCadre")
        current_id_ca = insert_CA(current_af_uuid)
        if current_id_ca:
            # Feed t_datasets
            query_update_ds = f"""
			UPDATE gn_meta.t_datasets
			SET id_acquisition_framework = {current_id_ca}
			WHERE unique_dataset_id = '{cur_ds_uuid}'
			"""
            cursor.execute(query_update_ds)
            conn.commit()
            print("UPDATE JDD")
            if DELETE_XML_FILE_AFTER_IMPORT == "True":
                os.remove("{}.xml".format(cur_ds_uuid))
    else:
        print(f"{cur_ds_uuid} not found")
