import { Injectable } from '@angular/core';
import { FormControl, FormBuilder, FormGroup, FormArray, Validators } from '@angular/forms';
import { AppConfig } from '../../../../conf/app.config';
import { Http } from '@angular/http';


@Injectable()
export class ContactFormService {
  currentTaxon:any;
  municipalities: string;
  indexCounting: number;
  nbCounting: Array<string>;
  indexOccurrence: number = 0;

  public releveForm: FormGroup;
  public occurrenceForm: FormGroup;
  public countingForm: FormArray;

  constructor(private _fb: FormBuilder, private _http:Http) {
    this.currentTaxon = {};
    this.indexCounting = 0;
    this.nbCounting = [''];
   }// end constructor

   getReleve(id) {
    return this._http.get(`${AppConfig.API_ENDPOINT}contact/releve/${id}`)
    .map(res => res.json());
  }

   initObservationForm(data?): FormGroup {
    return this._fb.group({
      geometry: [data ? data.geometry: null, Validators.required],
      properties: this._fb.group({
        id_releve_contact : [data ? data.properties.id_releve_contact : null],
        id_dataset: [data ? data.properties.id_dataset:null, Validators.required],
        id_digitiser : null,
        date_min: [data ? this.formatDate(data.properties.date_min): null, Validators.required],
        date_max: [data ? this.formatDate(data.properties.date_max): null, Validators.required],
        altitude_min: data ? data.properties.altitude_min: null,
        altitude_max : data ? data.properties.altitude_max: null,
        deleted: false,
        municipalities : null,
        meta_device_entry: 'web',
        comment: data ? data.properties.comment: null,
        observers: [data ? this.formatObservers(data.properties.observers): null, Validators.required],
        t_occurrences_contact: [new Array()]
      })
    });
   }

   initOccurrenceForm(data?): FormGroup {
    return this._fb.group({
      id_releve_contact : [data ? data.id_releve_contact : null],
      id_nomenclature_obs_technique : [data ? data.id_nomenclature_obs_technique : null, Validators.required],
      id_nomenclature_obs_meth: data ? data.id_nomenclature_obs_meth : null,
      id_nomenclature_bio_condition: [data ? data.id_nomenclature_bio_condition : null, Validators.required],
      id_nomenclature_bio_status : data ? data.id_nomenclature_bio_status : null,
      id_nomenclature_naturalness : data ? data.id_nomenclature_naturalness : null,
      id_nomenclature_exist_proof: data ? data.id_nomenclature_exist_proof : null,
      id_nomenclature_valid_status: data ? data.id_nomenclature_valid_status : null,
      id_nomenclature_diffusion_level: data ? data.id_nomenclature_diffusion_level : null,
      id_validator: null,
      determiner: '',
      determination_method: data ? data.determination_method : '',
      cd_nom: [data ? data.cd_nom : null, Validators.required],
      nom_cite: data ? data.nom_cite : '',
      meta_v_taxref: "Taxref V9.0",
      sample_number_proof: data ? data.sample_number_proof : '',
      digital_proof: data ? data.digital_proof : '',
      non_digital_proof:data ? data.non_digital_proof : '',
      deleted: false,
      comment: data ? data.comment : '',
      cor_counting_contact: ''
    })
  }


   initCounting(data?): FormGroup {
    return this._fb.group({
      id_nomenclature_life_stage: [data ? data.id_nomenclature_life_stage : null, Validators.required],
      id_nomenclature_sex: [data ? data.id_nomenclature_sex : null, Validators.required],
      id_nomenclature_obj_count: [data ? data.id_nomenclature_obj_count : null, Validators.required],
      id_nomenclature_type_count: data ? data.id_nomenclature_type_count : null,
      count_min : data ? data.count_min : null,
      count_max : data ? data.count_max : null
    });
    }


  initCountingArray(data?: Array<any>): FormArray {
    const arrayForm = this._fb.array([]);

    if (data) {
      for (let i = 0; i < data.length; i++) {
        arrayForm.push(this.initCounting(data[i]));
      }
    } else {
      arrayForm.push(this.initCounting());
    }
    return arrayForm;
  }


  addCounting(countingForm: FormArray) {
    this.indexCounting += 1;
    this.nbCounting.push('');
    const countingCtrl = this.initCounting();
    countingForm.push(countingCtrl);
    }

  removeCounting(index: number, countingForm: FormArray) {
    //countingForm.controls.splice(index, 1);
    countingForm.removeAt(index);
    countingForm.value.splice(index, 1);
    this.nbCounting.splice(index, 1);

  }

  updateTaxon(taxon) {
     this.currentTaxon = taxon;
   }

  formatObservers(observers){
    const observersTab = [];
    observers.forEach(observer => {
      observer['nom_complet'] = observer.nom_role + ' ' + observer.prenom_role
      observersTab.push(observer);
    });
    return observersTab;
  }

  formatDate(strDate) {
    const date = new Date(strDate);
    return {
      'year': date.getFullYear(),
      'month': date.getMonth() + 1,
      'day': date.getDate()
    }
  }



}