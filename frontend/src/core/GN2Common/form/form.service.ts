import { Injectable } from '@angular/core';
import { FormControl, FormBuilder, FormGroup, FormArray } from '@angular/forms';
import {  } from '@angular/forms';

@Injectable()
export class FormService {
  currentTaxon:any;
  taxonsList: Array<any>;
  indexCounting: number;
  nbCounting: Array<string>;
  contactForm: FormGroup;
  occurrenceForm : FormGroup;
  countingForm : FormArray;

  constructor(private _fb: FormBuilder) {
    this.currentTaxon = {};
    this.indexCounting = 0;
    this.nbCounting = [''];
    this.taxonsList = [];
   }// end constructor

   initObservationForm(): FormGroup{
    return this._fb.group({
      observers:'',
      dateMin: '',
      dateMax: '',
      dataSet: '',
      comment: '',
      t_occurrences_contact: this._fb.array([])
      }); 
   }

   initOccurrenceForm():FormGroup{
    return this._fb.group({
      id_nomenclature_obs_technique :'',
      id_nomenclature_obs_meth: '',
      id_nomenclature_bio_condition:'',
      id_nomenclature_bio_status :'',
      id_nomenclature_naturalness :'',
      determination_method:'',
      determiner:'',
      digital_proof:'',
      non_digital_proof:'',
      cd_nom:'',
      comment:'',
      cor_counting_contact: ''
    })
  }


   initCounting(): FormGroup {
    return this._fb.group({
      id_nomenclature_life_stage:'',
      id_nomenclature_sex:'',
      id_nomenclature_obj_count: '',
      id_nomenclature_type_count:'',
      count_min :'',
      count_max :''
    })
  }

  initCountingArray():FormArray{
    const arrayForm = this._fb.array([])
    arrayForm.push(this.initCounting());
    return arrayForm
  }

  addOccurence(occurenceForm:FormGroup, observationForm: FormGroup, countingForm:FormArray){
    // push the counting(s) in occurrenceForm
    occurenceForm.value.cor_counting_contact = countingForm.value;
    // push the current occurence in the observationForm   
    observationForm.value.t_occurrences_contact.push(occurenceForm.value)
    // reset counting
    this.nbCounting = [''];
    this.indexCounting = 0;
  }

  addCounting(countingForm:FormArray){
    this.indexCounting += 1;
    this.nbCounting.push('');
    const countingCtrl = this.initCounting();
    countingForm.push(countingCtrl);
    }
  
  removeCounting(index:number, coutingForm:FormArray){
    coutingForm.value.splice(index, 1);
    this.nbCounting.splice(index, 1);
  }

   updateTaxon(taxon) {
     this.currentTaxon = taxon;
   }

}