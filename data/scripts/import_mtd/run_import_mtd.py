''' 
	Script importing metadata in GeoNature DataBase based on uuid of datasets to import
	Use the inpn webservice to get corresponding xml files. Works with datasets and acquisition frameworks, not yet with parents acquisition frameworks (to do)
'''
import requests
import psycopg2
import xml.etree.ElementTree as ET
import os

import configparser
from config import *


# Connecting to DB and openning a cursor
try:
	conn = psycopg2.connect(SQLALCHEMY_DATABASE_URI)
except Exception as e:
	print("Connexion à la base impossible")

cursor = conn.cursor()

'''
Constants
'''

# Namespaces for metadata XML files
xml_namespaces = {'gml' : 'http://www.opengis.net/gml/3.2','ca' : 'http://inpn.mnhn.fr/mtd','jdd' : 'http://inpn.mnhn.fr/mtd', 'xlink' : 'http://www.w3.org/1999/xlink', 'xsi' : 'http://www.w3.org/2001/XMLSchema-instance'}

# Paths to different king of informations in XML files
af_main = 'gml:featureMember/ca:CadreAcquisition/ca:'
af_temp_ref = 'gml:featureMember/ca:CadreAcquisition/ca:ReferenceTemporelle/ca:'
af_main_actor = 'gml:featureMember/ca:CadreAcquisition/ca:acteurPrincipal/ca:ActeurType/ca:'
ds_main = 'gml:featureMember/jdd:JeuDeDonnees/jdd:'
ds_bbox = 'gml:featureMember/jdd:JeuDeDonnees/jdd:empriseGeographique/jdd:BoundingBox/jdd:'
ds_contact_pf = 'gml:featureMember/jdd:JeuDeDonnees/jdd:pointContactPF/jdd:ActeurType/jdd:'

'''
Parsing functions
	3 distinct functions used to get 3 kinds of data, parsing XML Files : 
		- single data under file root or non-repeatable node, (dataset and acquisition framework name, bbox...)
		- tuple data under file root, (territories, keywords...)
		- single data under repeatable nodes, themself under file root (publications, actors...)
'''

def get_single_data(path, tag):
	#path = af_main & tags = ['identifiantCadre','libelle','description','estMetaCadre','typeFinancement','niveauTerritorial','precisionGeographique','cibleEcologiqueOuGeologique','descriptionCible','dateCreationMtd','dateMiseAJourMtd']
	#path = af_temp_ref & tags = ['dateLancement','dateCloture']
	#path = af_main_actor & tags = ['mail','nomPrenom','roleActeur','organisme','idOrganisme']
	#path = ds_main & tags = ['identifiantJdd','identifiantCadre','libelle','libelleCourt','description','typeDonnees','objectifJdd','domaineMarin','domaineTerrestre','dateCreation','dateRevision']
	#path = ds_bbox & tags = ['borneNord','borneSud','borneEst','borneOuest']
	#path = ds_contact_pf & tags = ['mail','nomPrenom','roleActeur','organisme','idOrganisme']
	try:
		data = root.find(path + tag, namespaces=xml_namespaces).text.replace("'","\'\'").replace("’",'\'\'').replace('"','').replace('\u202f'," ")
		if data != None:
			return(str('\''+data+'\''))
		else :
			return(str('\'\''))
	except Exception as e:
		return(str('\'\''))

def get_tuple_data(path, tag):
	#path = af_main & tags = ['motCle','objectifCadre','voletSINP','territoire']
	#path = ds_main & tags = ['motCle','territoire']
	data = []
	try:
		datas = root.findall(path+tag, namespaces=xml_namespaces)
		if datas == []:
			return(str('\'\''))
		else:
			for row in datas:
				data.append(str('\''+row.text.replace("'","\'\'").replace("’",'\'\'').replace('"','').replace('\u202f'," ")+'\''))
			return(data)
	except Exception as e:
		return(str('\'\''))

def get_inner_data(object, iter, tag):
	# Object = af_publications, iter = cur_publi, tags = ['referencePublication','URLPublication']
	# Object = ds_protocols, iter = cur_proto, tags = ['libelleProtocole','descriptionProtocole','url']
	# Object = ds_pointscontacts, iter = point_contact, 
	# Object = af_othersactors, iter = other_actor, tags = ['nomPrenom', 'mail', 'roleActeur', 'organisme', 'idOrganisme']
	try :
		cur_data=object[iter].find('ca:'+tag, xml_namespaces).text.replace("'","\'\'").replace("’",'\'\'').replace('"','').replace('\u202f'," ")
		if cur_data!='':
			return('\''+cur_data+'\'')
		else :
			return(str("''"))
	except Exception as e:
		return(str("''"))


'''
Datatype protocols 
	Only protocols with a name are considered. Protocol name is the reference used as "key" for import
	WARNING : on 490 tested datasets, no one had protocol name stored in xml files. So, no protocols have been created... (only url most of time)
'''

def get_known_protocols():
 	protocols=[]
 	cursor.execute('SELECT DISTINCT protocol_name FROM gn_meta.sinp_datatype_protocols')
 	protos = cursor.fetchall()
 	for proto in protos:
 		protocols.append(str(proto).replace('"',"'"))
 	return(protocols)

def insert_sinp_datatype_protocols(cur_protocol_name,cur_protocol_desc,cur_protocol_url):
	# Protocol type not found in XML files, by default 'inconnu' 
 	create_protocol='INSERT INTO gn_meta.sinp_datatype_protocols (protocol_name,protocol_desc,id_nomenclature_protocol_type,protocol_url)' \
 		+ ' VALUES (\''+cur_protocol_name+'\', \''+cur_protocol_desc+'\', SELECT(ref_nomenclatures.get_id_nomenclature(\'TYPE_PROTOCOLE\', \'0\')), \''+cur_protocol_url+'\')'
 	cursor.execute(create_protocol)
 	conn.commit()
 	print('New protocol imported')

def update_sinp_datatype_protocols(cur_protocol_name,cur_protocol_desc,cur_protocol_url):
	# Protocol type not found in XML files, by default 'inconnu' 
 	update_protocol='UPDATE gn_meta.sinp_datatype_protocols SET protocol_desc=\''+cur_protocol_desc+'\', ' \
 		+ 'id_nomenclature_protocol_type=ref_nomenclatures.get_id_nomenclature(\'TYPE_PROTOCOLE\', \'0\'), protocol_url=\''+cur_protocol_url \
 		+ '\' WHERE protocol_name=\''+cur_protocol_name+'\''
 	cursor.execute(update_protocol)
 	conn.commit()
 	print('Existing protocol updated')


'''
Datatype publications
	Only publications with a name are considered. Publication name is the reference used as "key" for import
'''

def get_known_publications():
	publications=[]
	cursor.execute('SELECT DISTINCT publication_reference FROM gn_meta.sinp_datatype_publications')
	pubs = cursor.fetchall()
	for pub in pubs:
		publications.append(str(pub).replace('"',"'"))
	return(publications)

def insert_sinp_datatype_publications(cur_publication, cur_url):
	create_publication='INSERT INTO gn_meta.sinp_datatype_publications (publication_reference,publication_url)' \
		+ ' VALUES ('+cur_publication+', '+cur_url+')'
	cursor.execute(create_publication)
	conn.commit()
	print('New publication created...')

def update_sinp_datatype_publications(cur_publication, cur_url):
	update_publication='UPDATE gn_meta.sinp_datatype_publications SET publication_url='+cur_url+' WHERE publication_reference='+cur_publication
	cursor.execute(update_publication)
	conn.commit()
	print('Existing publication updated...')


'''
Actors : organisms (bib_organismes) and persons (t_roles)
'''

# Organisms
def get_known_organisms():
	cursor.execute('SELECT DISTINCT uuid_organisme FROM utilisateurs.bib_organismes')
	results = str(cursor.fetchall())
	known = results.replace("(","").replace(")","").replace("[","").replace("]","").replace(",","").replace("'","").split(" ")
	return(known)

def insert_organism(cur_organism_uuid, cur_organism_name):
	create_organism = 'INSERT INTO utilisateurs.bib_organismes (uuid_organisme,nom_organisme) VALUES ('+cur_organism_uuid+', '+cur_organism_name+')'
	cursor.execute(create_organism)
	conn.commit()
	print('New organism created...')

def update_organism(cur_organism_uuid, cur_organism_name):
	update_organism = 'UPDATE utilisateurs.bib_organismes SET uuid_organisme='+cur_organism_uuid+', nom_organisme='+cur_organism_name \
		+' WHERE uuid_organisme='+str.lower(cur_organism_uuid)
	cursor.execute(update_organism)
	conn.commit()
	print('Existing organism updated...')

# Persons
def get_known_persons():
	cursor.execute('SELECT DISTINCT nom_role||(CASE WHEN prenom_role=\'\' THEN \'\' ELSE \' \'||prenom_role END) FROM utilisateurs.t_roles WHERE groupe=\'False\'')
	return(str(cursor.fetchall()).replace('"',"'"))

def insert_person(cur_person_name, cur_person_mail):
	if len(cur_person_name.rsplit(' ', 1))==2:
		role_name = cur_person_name.replace("'","").rsplit(' ', 1)[0]
		role_firstname = cur_person_name.replace("'","").rsplit(' ', 1)[1]
	else :
		role_name = cur_person_name.replace("'","")
		role_firstname = ''
	create_role = 'INSERT INTO utilisateurs.t_roles (nom_role, prenom_role, email, id_organisme) VALUES (\''\
		+role_name+'\', \''+role_firstname+'\', \''+cur_person_mail.replace("'",'')+'\', \''+str(DEFAULT_ID_ORGANISME)+'\')'
	cursor.execute(create_role)
	conn.commit()
	print('New person created...')

def update_person(cur_person_name, cur_person_mail):
	if len(cur_person_name.rsplit(' ', 1))==2:
		role_name = cur_person_name.replace("'","").rsplit(' ', 1)[0]
		role_firstname = cur_person_name.replace("'","").rsplit(' ', 1)[1]
	else :
		role_name = cur_person_name.replace("'","")
		role_firstname = ''
	update_role = 'UPDATE utilisateurs.t_roles SET nom_role=\''+role_name+'\', prenom_role=\''+role_firstname \
		+ '\', email=\''+cur_person_mail.replace("'",'')+'\', id_organisme=\''+str(DEFAULT_ID_ORGANISME)+'\' '\
		+ 'WHERE nom_role||(CASE WHEN prenom_role=\'\' THEN \'\' ELSE \' \'||prenom_role END)=\''+cur_person_name+'\''
	cursor.execute(update_role)
	conn.commit()
	print('Existing person updated...')


'''
Acquisition frameworks
'''

# Check existing to avoid duplicates
def get_known_af(): 
	cursor.execute('SELECT DISTINCT unique_acquisition_framework_id FROM gn_meta.t_acquisition_frameworks')
	results = str(cursor.fetchall())
	known = results.replace("(","").replace(")","").replace("[","").replace("]","").replace(",","").replace("'","").split(" ")
	return(known)

def insert_update_t_acquisition_frameworks(action,cur_af_uuid):
	identifiantCadre=get_single_data(af_main,'identifiantCadre')
	libelle=get_single_data(af_main,'libelle')
	description=get_single_data(af_main,'description')
	motCle='\''+str(get_tuple_data(af_main, 'motCle')).replace("'","").replace("[","").replace("]","").replace('"','')+'\''
	descriptionCible=get_single_data(af_main,'descriptionCible')
	cibleEcologiqueOuGeologique=get_single_data(af_main,'cibleEcologiqueOuGeologique')
	precisionGeographique=get_single_data(af_main, 'precisionGeographique')
	#
	# territorial level : DEFAULT='National'
	if get_single_data(af_main,'niveauTerritorial')=='\'\'':
		id_niveauTerritorial='(SELECT n.id_nomenclature FROM ref_nomenclatures.t_nomenclatures n,' \
			+'ref_nomenclatures.bib_nomenclatures_types t WHERE t.id_type=n.id_type AND t.mnemonique=\'NIVEAU_TERRITORIAL\' AND' \
			+' cd_nomenclature=\'3\')::integer'
	else :
		id_niveauTerritorial='(SELECT n.id_nomenclature FROM ref_nomenclatures.t_nomenclatures n,' \
			+'ref_nomenclatures.bib_nomenclatures_types t WHERE t.id_type=n.id_type AND t.mnemonique=\'NIVEAU_TERRITORIAL\' AND' \
			+' cd_nomenclature='+get_single_data(af_main,'niveauTerritorial')+')::integer'
	# Financing Type : DEFAULT="Publique"
	if get_single_data(af_main,'typeFinancement')=='\'\'':
		id_typeFinancement='(SELECT n.id_nomenclature FROM ref_nomenclatures.t_nomenclatures n, ref_nomenclatures.bib_nomenclatures_types t  WHERE' \
			+' t.id_type=n.id_type AND t.mnemonique=\'TYPE_FINANCEMENT\' AND cd_nomenclature=\'1\')::integer'
	else :
		id_typeFinancement='(SELECT n.id_nomenclature FROM ref_nomenclatures.t_nomenclatures n, ref_nomenclatures.bib_nomenclatures_types t  WHERE' \
			+' t.id_type=n.id_type AND t.mnemonique=\'TYPE_FINANCEMENT\' AND cd_nomenclature='+get_single_data(af_main,'typeFinancement')+')::integer'
	# estMetaCadre : DEFAULT=False
	if get_single_data(af_main,'estMetaCadre')=='\'\'':
		estMetaCadre='false'
	else:
		estMetaCadre=get_single_data(af_main,'estMetaCadre')
	# dateLancement : DEFAULT='01/01/1800'
	if get_single_data(af_temp_ref,'dateLancement')=='\'\'':
		dateLancement='(SELECT \'01/01/1800\'::timestamp without time zone)'
	else:
		dateLancement=get_single_data(af_temp_ref,'dateLancement')+'::timestamp without time zone'
	# dateCloture
	if get_single_data(af_temp_ref,'dateCloture')=='\'\'':
		dateCloture='NULL'
	else:
		dateCloture=get_single_data(af_temp_ref,'dateCloture')+'::timestamp without time zone'
	# dateCreationMtd
	if get_single_data(af_main,'dateCreationMtd')=='\'\'':
		dateCreationMtd='NULL'
	else:
		dateCreationMtd=get_single_data(af_main,'dateCreationMtd')+'::timestamp without time zone'	
	# dateMiseAJourMtd
	if get_single_data(af_main,'dateMiseAJourMtd')=='\'\'':
		dateMiseAJourMtd='NULL'
	else:
		dateMiseAJourMtd=get_single_data(af_main,'dateMiseAJourMtd')+'::timestamp without time zone'
	# Write and run query
	if action=='create':
		cur_query = 'INSERT INTO gn_meta.t_acquisition_frameworks(unique_acquisition_framework_id, acquisition_framework_name, '\
			+'acquisition_framework_desc, id_nomenclature_territorial_level, territory_desc, keywords, id_nomenclature_financing_type'\
			+', target_description, ecologic_or_geologic_target, is_parent, acquisition_framework_start_date, acquisition_framework_end_date'\
			+', meta_create_date, meta_update_date)'\
			+'VALUES ('+identifiantCadre+', '+libelle+', '+description+', '+id_niveauTerritorial+', '+precisionGeographique+', '+motCle+', '+id_typeFinancement \
			+', '+descriptionCible+', '+cibleEcologiqueOuGeologique+', '+estMetaCadre+', '+dateLancement+', '+dateCloture \
			+', '+dateCreationMtd+', '+dateMiseAJourMtd+');'
		result = 'New acquisition framework created...'
	elif action=='update':
		cur_query='UPDATE gn_meta.t_acquisition_frameworks SET acquisition_framework_name='+libelle+', acquisition_framework_desc='+description \
			+ ', id_nomenclature_territorial_level='+id_niveauTerritorial+', territory_desc='+precisionGeographique+', keywords='+motCle \
			+ ', id_nomenclature_financing_type='+id_typeFinancement+', target_description='+descriptionCible+', ecologic_or_geologic_target='+cibleEcologiqueOuGeologique \
			+ ', is_parent='+estMetaCadre+', acquisition_framework_start_date='+dateLancement+', acquisition_framework_end_date='+dateCloture \
			+ ', meta_create_date='+dateCreationMtd+', meta_update_date='+dateMiseAJourMtd+' WHERE unique_acquisition_framework_id=\''+cur_af_uuid+'\''
		result = ('Existing acquisition framework updated...')
	cursor.execute(cur_query)
	conn.commit()
	print(result)

# Functions deleting existing cor before create or update cor tables
def delete_cor_af(table,cur_af_uuid):
	# tables : [voletsinp, objectif, territory, publication, actor]
	cur_delete_query='DELETE FROM gn_meta.cor_acquisition_framework_'+table+' WHERE id_acquisition_framework=(SELECT id_acquisition_framework FROM gn_meta.t_acquisition_frameworks WHERE unique_acquisition_framework_id=\''+cur_af_uuid+'\')'
	cursor.execute(cur_delete_query)
	conn.commit()

# Functions feeding cor_acquisition_framework tables 
def insert_cor_af_voletsinp(cur_af_uuid, cur_volet_sinp):
	cur_insert_query='INSERT INTO gn_meta.cor_acquisition_framework_voletsinp (id_acquisition_framework,id_nomenclature_voletsinp)' \
		+'VALUES ((SELECT id_acquisition_framework FROM gn_meta.t_acquisition_frameworks WHERE unique_acquisition_framework_id=\''+cur_af_uuid+'\'), '\
		+'(SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE id_type=\'113\' AND cd_nomenclature=\''+cur_volet_sinp+'\'))'
	cursor.execute(cur_insert_query)
	conn.commit()

def insert_cor_af_objectifs(cur_af_uuid, cur_objectif):
	cur_insert_query='INSERT INTO gn_meta.cor_acquisition_framework_objectif (id_acquisition_framework,id_nomenclature_objectif)' \
		+'VALUES ((SELECT id_acquisition_framework FROM gn_meta.t_acquisition_frameworks WHERE unique_acquisition_framework_id=\''+cur_af_uuid+'\'), '\
		+'(SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE id_type=\'108\' AND cd_nomenclature=\''+cur_objectif+'\'))'
	cursor.execute(cur_insert_query)
	conn.commit()

def insert_cor_af_territory(cur_af_uuid,cur_territory):
	cur_insert_query='INSERT INTO gn_meta.cor_acquisition_framework_territory (id_acquisition_framework,id_nomenclature_territory)' \
		+'VALUES ((SELECT id_acquisition_framework FROM gn_meta.t_acquisition_frameworks WHERE unique_acquisition_framework_id=\''+cur_af_uuid+'\'), '\
		+'ref_nomenclatures.get_id_nomenclature(\'TERRITOIRE\', \''+cur_territory+'\'))'
	cursor.execute(cur_insert_query)
	conn.commit()

def insert_cor_af_publications(cur_af_uuid,af_publications):
	cur_insert_query='INSERT INTO gn_meta.cor_acquisition_framework_publication (id_acquisition_framework,id_publication)' \
		+'VALUES ((SELECT id_acquisition_framework FROM gn_meta.t_acquisition_frameworks WHERE unique_acquisition_framework_id=\''+cur_af_uuid+'\'), '\
		+'(SELECT id_publication FROM gn_meta.sinp_datatype_publications WHERE publication_reference='+cur_publication+'))'
	cursor.execute(cur_insert_query)
	conn.commit()

def insert_cor_af_actor_organism(cur_af_uuid,cur_organism_uuid,cur_actor_role):
	cur_insert_query='INSERT INTO gn_meta.cor_acquisition_framework_actor (id_acquisition_framework,id_organism,id_nomenclature_actor_role)' \
		+'VALUES ((SELECT id_acquisition_framework FROM gn_meta.t_acquisition_frameworks WHERE unique_acquisition_framework_id=\''+cur_af_uuid+'\'), '\
		+'(SELECT id_organisme FROM utilisateurs.bib_organismes WHERE uuid_organisme='+str.lower(cur_organism_uuid)+'), ' \
		+'ref_nomenclatures.get_id_nomenclature(\'ROLE_ACTEUR\', '+cur_actor_role+'))'
	try :
		cursor.execute(cur_insert_query)
	except :
		pass
	conn.commit()


def insert_cor_af_actor_person(cur_af_uuid,cur_person_name,cur_actor_role):
	cur_insert_query='INSERT INTO gn_meta.cor_acquisition_framework_actor (id_acquisition_framework,id_role,id_nomenclature_actor_role)' \
		+'VALUES ((SELECT id_acquisition_framework FROM gn_meta.t_acquisition_frameworks WHERE unique_acquisition_framework_id=\''+cur_af_uuid+'\'), '\
		+'(SELECT id_role FROM utilisateurs.t_roles WHERE nom_role||(CASE WHEN prenom_role=\'\' THEN \'\' ELSE \' \'||prenom_role END)=\''+cur_person_name+'\'), ' \
		+'ref_nomenclatures.get_id_nomenclature(\'ROLE_ACTEUR\', '+cur_actor_role+'))'
	try :
		cursor.execute(cur_insert_query)
	except :
		pass
	conn.commit()


'''
	Datasets 
'''
def get_known_ds(): 
	cursor.execute('SELECT DISTINCT unique_dataset_id FROM gn_meta.t_datasets')
	results = str(cursor.fetchall())
	known = results.replace("(","").replace(")","").replace("[","").replace("]","").replace(",","").replace("'","").split(" ")
	return(known)

def insert_update_t_datasets(action,cur_ds_uuid):
	unique_dataset_id = get_single_data(ds_main,'identifiantJdd')
	id_acquisition_framework = '(SELECT id_acquisition_framework FROM gn_meta.t_acquisition_frameworks WHERE unique_acquisition_framework_id='\
		+ str.lower(get_single_data(ds_main,'identifiantCadre'))+')'
	dataset_name = get_single_data(ds_main,'libelle')
	dataset_shortname = get_single_data(ds_main,'libelleCourt')
	if get_single_data(ds_main,'description')!='':
		dataset_desc = get_single_data(ds_main,'description')
	else :
		dataset_desc = '\'\''
	keywords='\''+str(get_tuple_data(ds_main, 'motCle')).replace("'","").replace("[","").replace("]","").replace('"','')+'\''
	marine_domain = get_single_data(ds_main, 'domaineMarin')
	terrestrial_domain = get_single_data(ds_main, 'domaineTerrestre')
	default_validity = 'true'
	bbox_west = get_single_data(ds_bbox, 'borneOuest')
	bbox_east = get_single_data(ds_bbox, 'borneEst')
	bbox_south = get_single_data(ds_bbox, 'borneSud')
	bbox_north = get_single_data(ds_bbox, 'borneNord')
	# Default value (information not found in xml files)
	id_nomenclature_collecting_method = 'ref_nomenclatures.get_id_nomenclature(\'METHO_RECUEIL\', \'12\')'
	# Default value = Données élémentaires d'échanges (information not found in xml files) 'Ne sait pas'
	id_nomenclature_data_origin = 'ref_nomenclatures.get_id_nomenclature(\'DS_PUBLIQUE\', \'NSP\')'
	# Default value (information not found in xml files) 'Ne sait pas'
	id_nomenclature_source_status = 'ref_nomenclatures.get_id_nomenclature(\'STATUT_SOURCE\', \'NSP\')'
	# Default value (information not found in xml files) 'Dataset'
	id_nomenclature_resource_type = 'ref_nomenclatures.get_id_nomenclature(\'RESOURCE_TYP\', \'1\')'
	# Default value (information not found in xml files) 'Occurrence de taxon'
	id_nomenclature_data_type = 'ref_nomenclatures.get_id_nomenclature(\'DATA_TYP\', \'1\')'
	# Default value
	active = 'false'
	# dateCreationMtd
	if get_single_data(ds_main,'dateCreation')=="''":
		meta_create_date='NULL'
	else:
		meta_create_date=get_single_data(ds_main,'dateCreation')+'::timestamp without time zone'
	# dateMiseAJourMtd
	if get_single_data(ds_main,'dateRevision')=="''" :
		meta_update_date='NULL'
	else :
		meta_update_date=get_single_data(ds_main,'dateRevision')+'::timestamp without time zone'
	# If several objectives, set default value 'Autre'
	if len(get_tuple_data(ds_main,'objectifJdd')) == 1 :
		id_nomenclature_dataset_objectif = 'ref_nomenclatures.get_id_nomenclature(\'JDD_OBJECTIFS\', '+get_single_data(ds_main,'objectifJdd')+')'
	else :	
		id_nomenclature_dataset_objectif = 'ref_nomenclatures.get_id_nomenclature(\'JDD_OBJECTIFS\', \'7.1\')'
	# If action is CREATE
	if action=='create':
		cur_query='INSERT INTO gn_meta.t_datasets(unique_dataset_id, id_acquisition_framework, dataset_name, dataset_shortname, '\
			+ 'dataset_desc, id_nomenclature_data_type, keywords, marine_domain, terrestrial_domain, id_nomenclature_dataset_objectif, '\
			+ 'bbox_west, bbox_east, bbox_south, bbox_north, id_nomenclature_collecting_method, id_nomenclature_data_origin, id_nomenclature_source_status, '\
			+ 'id_nomenclature_resource_type, default_validity, active, meta_create_date, meta_update_date)' \
			+ 'VALUES ('+unique_dataset_id+', '+id_acquisition_framework+', '+dataset_name+', '+dataset_shortname+',' \
			+ dataset_desc+', '+id_nomenclature_data_type+', '+keywords+', '+marine_domain+','+terrestrial_domain+', '+id_nomenclature_dataset_objectif+ ', ' \
			+ bbox_west+', '+bbox_east+', '+bbox_south+', '+bbox_north+', '+id_nomenclature_collecting_method+', '+id_nomenclature_data_origin+', '\
			+id_nomenclature_source_status+', '+id_nomenclature_resource_type+', '+default_validity+', '+active+','+meta_create_date+', '+meta_update_date+' );'
		result = 'New dataset created...'
	elif action=='update':
		cur_query='UPDATE gn_meta.t_datasets SET id_acquisition_framework='+id_acquisition_framework+', dataset_name='+dataset_name \
			+ ', dataset_shortname='+dataset_shortname+', dataset_desc='+dataset_desc+', id_nomenclature_data_type='+id_nomenclature_data_type \
			+ ', keywords='+keywords+', marine_domain='+marine_domain+', terrestrial_domain='+terrestrial_domain \
			+ ', id_nomenclature_dataset_objectif='+id_nomenclature_dataset_objectif+', bbox_west='+bbox_west+', bbox_east='+bbox_east \
			+ ', bbox_south='+bbox_south+', bbox_north='+bbox_north+', id_nomenclature_collecting_method='+id_nomenclature_collecting_method \
			+ ', id_nomenclature_data_origin='+id_nomenclature_data_origin+', id_nomenclature_source_status='+id_nomenclature_source_status \
			+ ', id_nomenclature_resource_type='+id_nomenclature_resource_type+', default_validity='+default_validity+', active='+active \
			+ ', meta_create_date='+meta_create_date+', meta_update_date='+meta_update_date+' WHERE unique_dataset_id=\''+cur_ds_uuid+'\''
		result = ('Existing dataset updated...')
	cursor.execute(cur_query)
	conn.commit()
	print(result)

# Functions deleting existing cor before create or update cor tables
def delete_cor_ds(table,cur_ds_uuid):
	# tables : [territory, protocol, actor]
	cur_delete_query='DELETE FROM gn_meta.cor_dataset_'+table+' WHERE id_dataset=(SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id=\''+cur_ds_uuid+'\')'
	cursor.execute(cur_delete_query)
	conn.commit()

def insert_cor_ds_territory(cur_ds_uuid, cur_territory):
	cur_insert_query='INSERT INTO gn_meta.cor_dataset_territory (id_dataset,id_nomenclature_territory)' \
		+'VALUES ((SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id=\''+cur_ds_uuid+'\'), '\
		+'ref_nomenclatures.get_id_nomenclature(\'TERRITOIRE\', \''+cur_territory+'\'))'
	cursor.execute(cur_insert_query)
	conn.commit()

def insert_cor_ds_protocol(cur_ds_uuid, cur_protocol):
	cur_insert_query='INSERT INTO gn_meta.cor_dataset_protocol(id_dataset, id_protocol)' \
		+'VALUES ((SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id=\''+cur_ds_uuid+'\'), '\
		+'(SELECT id_protocol FROM gn_meta.sinp_datatype_protocols WHERE protocol_name=\''+cur_protocol_name+'\'))'
	cursor.execute(cur_insert_query)
	conn.commit()

def insert_cor_ds_actor_organism(cur_ds_uuid, cur_organism_uuid, cur_actor_role):
	cur_insert_query='INSERT INTO gn_meta.cor_dataset_actor (id_dataset,id_organism,id_nomenclature_actor_role)' \
		+'VALUES ((SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id=\''+cur_ds_uuid+'\'), '\
		+'(SELECT id_organisme FROM utilisateurs.bib_organismes WHERE uuid_organisme='+str.lower(cur_organism_uuid)+'), ' \
		+'ref_nomenclatures.get_id_nomenclature(\'ROLE_ACTEUR\', '+cur_actor_role+'))'
	try :
		cursor.execute(cur_insert_query)
	except :
		pass
	conn.commit()

def insert_cor_ds_actor_person(cur_ds_uuid, cur_person_name, cur_actor_role):
	cur_insert_query='INSERT INTO gn_meta.cor_dataset_actor (id_dataset,id_role,id_nomenclature_actor_role)' \
		+'VALUES ((SELECT id_dataset FROM gn_meta.t_datasets WHERE unique_dataset_id=\''+cur_ds_uuid+'\'), '\
		+'(SELECT id_role FROM utilisateurs.t_roles WHERE nom_role||(CASE WHEN prenom_role=\'\' THEN \'\' ELSE \' \'||prenom_role END)=\''+cur_person_name+'\'), ' \
		+'ref_nomenclatures.get_id_nomenclature(\'ROLE_ACTEUR\', '+cur_actor_role+'))'
	try :
		cursor.execute(cur_insert_query)
	except :
		pass
	conn.commit()


''' 
	Getting XML Files & pushing Acquisition Frameworks data in GeoNature DataBase
'''

# Getting uuid list of Acquisition Framworks to import 
cursor.execute('SELECT DISTINCT \"'+CHAMP_ID_CA+'\" FROM '+TABLE_DONNEES_INPN)
af_uuid_list=cursor.fetchall()

# Parse and import data in GeoNature database
for af_iter in range(len(af_uuid_list)):
	cur_af_uuid = af_uuid_list[af_iter][0]
	if cur_af_uuid not in get_known_af():
		action='create'
	else:
		action='update'
	# Get and parse corresponding XML File
	af_URL = "https://inpn.mnhn.fr/mtd/cadre/export/xml/GetRecordById?id={}".format(cur_af_uuid.upper())
	open('{}.xml'.format(cur_af_uuid), 'wb').write(requests.get(af_URL).content)
	root = ET.parse('{}.xml'.format(cur_af_uuid)).getroot()
	# Feed t_acquisition_frameworks
	insert_update_t_acquisition_frameworks(action,cur_af_uuid)
	# Feed cor_acquisition_framework_voletsinp
	delete_cor_af('voletsinp',cur_af_uuid)
	volets_sinp=get_tuple_data(af_main,'voletSINP')
	if volets_sinp != '\'\'':
		for volet_iter in range(len(volets_sinp)):
			cur_volet_sinp=volets_sinp[volet_iter].replace("'","")
			insert_cor_af_voletsinp(cur_af_uuid, cur_volet_sinp)
	# Feed cor_acquisition_framework_objectif
	delete_cor_af('objectif',cur_af_uuid)
	af_objectifs=get_tuple_data(af_main,'objectif')
	if af_objectifs != '\'\'':
		for objectif_iter in range(len(af_objectifs)):
			cur_objectif=af_objectifs[objectif_iter].replace("'","")
			insert_cor_af_objectifs(cur_af_uuid, cur_objectif)
	# if exists : feed cor_acquisition_framework_territory 
	cursor.execute("select exists(select * from information_schema.tables where table_name=\'cor_acquisition_framework_territory\')") 
	if cursor.fetchone()[0]==True:
		delete_cor_af('territory',cur_af_uuid)
		af_territories=get_tuple_data(af_main,'territoire')
		if af_territories != '\'\'':
			for territory_iter in range(len(af_territories)):
				cur_territory=af_territories[territory_iter].replace("'","")
				insert_cor_af_territory(cur_af_uuid, cur_territory)
	# Create or update publications + Feed cor_acquisition_framework_publication
	# Get publication data
	delete_cor_af('publication',cur_af_uuid)
	af_publications=root.findall('gml:featureMember/ca:CadreAcquisition/ca:referenceBiblio/ca:Publication',xml_namespaces)
	for cur_publi in range(len(af_publications)) :
		cur_publication = get_inner_data(af_publications, cur_publi, 'referencePublication')
		if get_inner_data(af_publications, cur_publi, 'URLPublication')!=None:
			cur_url = get_inner_data(af_publications, cur_publi, 'URLPublication')
		else : 
			cur_url = '\'\''
		# Create or update publication
		if '('+cur_publication.replace("''","'")+',)' not in get_known_publications() :
			insert_sinp_datatype_publications(cur_publication, cur_url)
		else :
			update_sinp_datatype_publications(cur_publication, cur_url)
		# Feed cor table
		insert_cor_af_publications(cur_af_uuid,cur_publication)
	# ACTORS
	# Create or update actors and feed cor table
	delete_cor_af('actor',cur_af_uuid)
	# For main actor (single)
	cur_actor_role = get_single_data(af_main_actor, 'roleActeur')
	# Person : name is the reference
	if get_single_data(af_main_actor, 'nomPrenom') != "''" :
		cur_person_name = get_single_data(af_main_actor, 'nomPrenom').replace('\t','').replace("'","").rstrip()
		if get_single_data(af_main_actor, 'mail')!= "''" :
			cur_person_mail = get_single_data(af_main_actor, 'mail').replace("'",'')
		else :
			cur_person_mail = ''
		if '(\''+cur_person_name.replace("'","")+'\',)' not in get_known_persons() :
			insert_person(cur_person_name, cur_person_mail)
		else :
			update_person(cur_person_name, cur_person_mail)
		insert_cor_af_actor_person(cur_af_uuid, cur_person_name, cur_actor_role)
	# Organism : the uuid is the reference
	if get_single_data(af_main_actor, 'idOrganisme') != "''" and get_single_data(af_main_actor, 'organisme') != "''" :
		cur_organism_uuid = get_single_data(af_main_actor, 'idOrganisme')
		cur_organism_name = get_single_data(af_main_actor, 'organisme')
		if str.lower(cur_organism_uuid).replace("'","") not in get_known_organisms():
			insert_organism(cur_organism_uuid, cur_organism_name)
		else :
			update_organism(cur_organism_uuid, cur_organism_name)
		insert_cor_af_actor_organism(cur_af_uuid, cur_organism_uuid, cur_actor_role)
	# For others actors
	af_othersactors = root.findall('gml:featureMember/ca:CadreAcquisition/ca:acteurAutre/ca:ActeurType',xml_namespaces)
	for other_actor in range(len(af_othersactors)) :
		cur_actor_role = get_inner_data(af_othersactors, other_actor, 'roleActeur')
		# Person : name is the reference
		if get_inner_data(af_othersactors, other_actor, 'nomPrenom') != "''" :
			cur_person_name = get_inner_data(af_othersactors, other_actor, 'nomPrenom').replace('\t','').replace("'","").rstrip()
			if get_inner_data(af_othersactors, other_actor, 'mail') != "''" :
				cur_person_mail = get_inner_data(af_othersactors, other_actor, 'mail')
			else :
				cur_person_mail = ''
			if '(\''+cur_person_name.replace("'","")+'\',)' not in get_known_persons() :
				insert_person(cur_person_name, cur_person_mail)
			else :
				update_person(cur_person_name, cur_person_mail)
			insert_cor_af_actor_person(cur_af_uuid, cur_person_name, cur_actor_role)
		# Organism : the uuid is the reference
		if get_inner_data(af_othersactors, other_actor, 'idOrganisme') != "''" and get_inner_data(af_othersactors, other_actor, 'organisme') != "''" :
			cur_organism_uuid = get_inner_data(af_othersactors, other_actor, 'idOrganisme')
			cur_organism_name = get_inner_data(af_othersactors, other_actor, 'organisme')
			if str.lower(cur_organism_uuid).replace("'","") not in get_known_organisms():
				insert_organism(cur_organism_uuid, cur_organism_name)
			else :
				update_organism(cur_organism_uuid, cur_organism_name)
			insert_cor_af_actor_organism(cur_af_uuid, cur_organism_uuid, cur_actor_role)
	# Delete files if choosen
	if DELETE_XML_FILE_AFTER_IMPORT=='True':
		os.remove('{}.xml'.format(cur_af_uuid))

'''
	Getting XML Files & pushing Datasets data in GeoNature DataBase
'''
# Getting uuid list of Acquisition Framworks to import 
cursor.execute('SELECT DISTINCT \"'+CHAMP_ID_JDD+'\" FROM '+TABLE_DONNEES_INPN)
ds_uuid_list=cursor.fetchall()

for ds_iter in range(len(ds_uuid_list)):
	cur_ds_uuid = ds_uuid_list[ds_iter][0]
	if cur_ds_uuid not in get_known_ds():
		action='create'
	else:
		action='update'
	# Get and parse corresponding XML File
	ds_URL = "https://inpn.mnhn.fr/mtd/cadre/jdd/export/xml/GetRecordById?id={}".format(cur_ds_uuid.upper())
	open('{}.xml'.format(cur_ds_uuid), 'wb').write(requests.get(ds_URL).content)
	root = ET.parse('{}.xml'.format(cur_ds_uuid)).getroot()
	# Feed t_datasets
	insert_update_t_datasets(action,cur_ds_uuid)
	# Feed cor territory
	delete_cor_ds('territory',cur_ds_uuid)
	ds_territories=get_tuple_data(ds_main,'territoire')
	if ds_territories != "''":
		for territory_iter in range(len(ds_territories)):
			cur_territory=ds_territories[territory_iter].replace("'","")
			insert_cor_ds_territory(cur_ds_uuid, cur_territory)
	# Feed cor protocol
	delete_cor_ds('protocol',cur_ds_uuid)
	ds_protocols=root.findall('gml:featureMember/jdd:JeuDeDonnees/jdd:protocoles/jdd:ProtocoleType',xml_namespaces)
	for cur_proto in range(len(ds_protocols)) :
		if get_inner_data(ds_protocols, cur_proto, 'libelleProtocole') !="''" : 
			cur_protocol_name = get_inner_data(ds_protocols, cur_proto, 'libelleProtocole')
			if get_inner_data(ds_protocols, cur_proto, 'descriptionProtocole')!=None:
				cur_protocol_desc = get_inner_data(ds_protocols, cur_proto, 'descriptionProtocole')
			else : 
				cur_protocol_desc = '\'\''
			if get_inner_data(ds_protocols, cur_proto, 'url')!=None:
				cur_protocol_url = get_inner_data(ds_protocols, cur_proto, 'url')
			else : 
				cur_protocol_url = '\'\''
			# Create or update publication
			if '(\''+cur_protocol_name.replace("''","'")+'\',)' not in get_known_protocols() :
				insert_sinp_datatype_protocols(cur_protocol_name,cur_protocol_desc,cur_protocol_url)
			else :
				update_sinp_datatype_protocols(cur_protocol_name,cur_protocol_desc,cur_protocol_url)
			insert_cor_ds_protocol(cur_ds_uuid, cur_protocol_name)
	# ACTORS
	# Create or update actors and feed cor table
	delete_cor_ds('actor',cur_ds_uuid)
	# For contact_points
	ds_pointscontacts = root.findall('gml:featureMember/jdd:JeuDeDonnees/jdd:pointContactJdd/jdd:ActeurType',xml_namespaces)
	for point_contact in range(len(ds_pointscontacts)) :
		# Person : name is the reference
		cur_actor_role = get_inner_data(ds_pointscontacts, point_contact, 'roleActeur')
		if get_inner_data(ds_pointscontacts, point_contact, 'nomPrenom') != "''" :
			cur_person_name = get_inner_data(ds_pointscontacts, point_contact, 'nomPrenom').replace('\t','').replace("'","").rstrip()
			if get_inner_data(ds_pointscontacts, point_contact, 'mail') != "''" :
				cur_person_mail = get_inner_data(ds_pointscontacts, point_contact, 'mail')
			else : 
				cur_person_mail = ''
			if '(\''+cur_person_name.replace("'","")+'\',)' not in get_known_persons() :
				insert_person(cur_person_name, cur_person_mail)
			else :
				update_person(cur_person_name, cur_person_mail)
			insert_cor_ds_actor_person(cur_ds_uuid, cur_person_name, cur_actor_role)
		# Organism : the uuid is the reference
		if get_inner_data(ds_pointscontacts, point_contact, 'idOrganisme') != "''" and get_inner_data(ds_pointscontacts, point_contact, 'organisme') != "''" :
			cur_organism_uuid = get_inner_data(ds_pointscontacts, point_contact, 'idOrganisme')
			cur_organism_name = get_inner_data(ds_pointscontacts, point_contact, 'organisme')
			if str.lower(cur_organism_uuid).replace("'","") not in get_known_organisms():
				insert_organism(cur_organism_uuid, cur_organism_name)
			else :
				update_organism(cur_organism_uuid, cur_organism_name)
			insert_cor_ds_actor_organism(cur_ds_uuid, cur_organism_uuid, cur_actor_role)
	# For PF_contact (single)
	cur_actor_role = get_single_data(ds_contact_pf, 'roleActeur')
	# Person : name is the reference
	if get_single_data(ds_contact_pf, 'nomPrenom') != "''" :
		cur_person_name = get_single_data(ds_contact_pf, 'nomPrenom').replace('\t','').replace("'","").rstrip()
		if get_single_data(ds_contact_pf, 'mail') != "''" :
			cur_person_mail = get_single_data(ds_contact_pf, 'mail').replace("'",'')
		else : 
			cur_person_mail = ''
		if '(\''+cur_person_name.replace("'","")+'\',)' not in get_known_persons() :
			insert_person(cur_person_name, cur_person_mail)
		else :
			update_person(cur_person_name, cur_person_mail)
		insert_cor_ds_actor_person(cur_ds_uuid, cur_person_name, cur_actor_role)
	# Organism : the uuid is the reference
	if get_single_data(ds_contact_pf, 'idOrganisme') != "''" and get_single_data(ds_contact_pf, 'organisme') != "''" :
		cur_organism_uuid = get_single_data(ds_contact_pf, 'idOrganisme')
		cur_organism_name = get_single_data(ds_contact_pf, 'organisme')
		if str.lower(cur_organism_uuid).replace("'","") not in get_known_organisms():
			insert_organism(cur_organism_uuid, cur_organism_name)
		else :
			update_organism(cur_organism_uuid, cur_organism_name)
		insert_cor_ds_actor_organism(cur_ds_uuid, cur_organism_uuid, cur_actor_role)
	# Delete files if choosen
	if DELETE_XML_FILE_AFTER_IMPORT=='True':
		os.remove('{}.xml'.format(cur_ds_uuid))
