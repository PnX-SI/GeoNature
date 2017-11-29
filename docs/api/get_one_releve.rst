================
API DOCS (draft)
================

get one releve
================

* url : ../pr_contact/releve/<id_releve_contact:interger>
* return json :
 
  ::  
  
	{
			"geometry": 
				{
					"coordinates": [
						6.5, 44.85
					], 
					"type": "Point"
				}, 
			"id": 1, 
			"type": "Feature", 
			"properties": {
				"id_releve_contact": 1,
				"id_dataset": 1,
				"id_digitiser": 1, 
				"date_min": "2017-01-01 00:00:00",
				"date_max": "2017-01-01 00:00:00", 
				"altitude_min": 1500, 
				"altitude_max": 1565,
				"meta_device_entry": "web", 
				"deleted": false,
				"meta_create_date": "None",  
				"meta_update_date": "None", 
				"comment": "exemple test",
				"observers": [
					{
						"prenom_role": "test", 
						"nom_role": "Administrateur",
						"id_role": 1
					}
				], 
				"occurrences": [
					{
						"id_occurrence_contact": 1,
						"id_releve_contact": 1,
						"id_nomenclature_obs_meth": 65,
						"id_nomenclature_bio_condition": 177,
						"id_nomenclature_bio_status": 30,
						"id_nomenclature_naturalness": 182,
						"id_nomenclature_exist_proof": 91,
						"id_nomenclature_valid_status": 347,
						"id_nomenclature_diffusion_level": 163,
						"id_validator": 1,
						"determiner": "gil",
						"determination_method": "gees",
						"cd_nom": 60612, 
						"nom_cite": "Lynx Bor\u00e9al", 
						"meta_v_taxref": "Taxref V9.0", 
						"sample_number_proof": "",
						"digital_proof": "",
						"non_digital_proof": "poil",
						"deleted": false,
						"meta_create_date": "2017-08-24 09:51:57.044894", 
						"meta_update_date": "2017-08-24 09:51:57.044894",
						"comment": "test",
						"countingContact": [
							{
								"id_counting_contact": 1,
								"id_occurrence_contact": 1, 
								"id_nomenclature_life_stage": 4,
								"id_nomenclature_sex": 190,  
								"id_nomenclature_obj_count": 166, 
								"id_nomenclature_type_count": 107, 
								"count_min": 55,
								"count_max": 60, 
							},
							{
								"id_counting_contact": 2,
								"id_occurrence_contact": 1, 
								"id_nomenclature_life_stage": 4,
								"id_nomenclature_sex": 191,  
								"id_nomenclature_obj_count": 166, 
								"id_nomenclature_type_count": 107, 
								"count_min": 5,
								"count_max": 5, 
							}
						]
					}
				],
				"digitiser": {"prenom_role": "test", "nom_role": "Administrateur", "id_role": 1} 
			}
		}

* Usage samples :
 
  ::  
  
        coordinates = array[] = myobject.geometry.coordinates
	long = array[] = myobject.geometry.coordinates[0]
	lat = array[] = myobject.geometry.coordinates[1]
	geometry_type = myobject.geometry.type
	
	altitude_min = monobjet.properties.altitude_min
	date_max = monobjet.properties.date_max
	
	observers = array[] = monobjet.properties.observers
	observateur1 = monobjet.properties.observer[0].id_role

	occurrences = array[] = monobjet.properties.occurrences
	cd_nom = monobjet.properties.occurrences[0].cd_nom

	countings = array[] = monobjet.properties.occurrences.countingContact
	sex = monobjet.properties.occurrences[0].countingContact[0].sex
	count_min = monobjet.properties.occurrences[0].countingContact[0].count_min
