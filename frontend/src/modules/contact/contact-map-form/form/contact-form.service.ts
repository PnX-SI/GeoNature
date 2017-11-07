import { Injectable } from '@angular/core';
import { FormControl, FormBuilder, FormGroup, FormArray, Validators } from '@angular/forms';
import { AppConfig } from '../../../../conf/app.config';
import { Http } from '@angular/http';
import { DataFormService } from '../../../../core/GN2Common/form/data-form.service';
import { ActivatedRoute, Router } from '@angular/router';
import { ContactConfig } from '../../contact.config';


@Injectable()
export class ContactFormService {
  public currentTaxon: any;
  public indexCounting: number;
  public nbCounting: Array<string>;
  public indexOccurrence: number = 0;
  public taxonsList = [];
  public showOccurrence: boolean;
  public editionMode: boolean;
  public isEdintingOccurrence: boolean;


  public releveForm: FormGroup;
  public occurrenceForm: FormGroup;
  public countingForm: FormArray;

  constructor(private _fb: FormBuilder, private _http:Http, private _dfs: DataFormService, private _router: Router) {
    this.currentTaxon = {};
    this.indexCounting = 0;
    this.nbCounting = [''];
    this.showOccurrence = false;
    this.isEdintingOccurrence = false;

    this._router.events.subscribe(value => {
      this.isEdintingOccurrence = false;
    });
   }// end constructor


   initObservationForm(): FormGroup {
    return this._fb.group({
      geometry: [null, Validators.required],
      properties: this._fb.group({
        id_releve_contact : null,
        id_dataset: [null, Validators.required],
        id_digitiser : null,
        date_min: [null, Validators.required],
        date_max: [null, Validators.required],
        hour_min: [null, Validators.pattern('^([0-9]|0[0-9]|1[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$')],
        hour_max: [null, Validators.pattern('^([0-9]|0[0-9]|1[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$')],
        altitude_min: null,
        altitude_max: null,
        deleted: false,
        meta_device_entry: 'web',
        comment: null,
        observers: [null,
           !ContactConfig.observers_txt ? Validators.required : null],
        observers_txt: [null, ContactConfig.observers_txt ? Validators.required : null ],
        t_occurrences_contact: [new Array()]
      })
    });
   }

   initOccurrenceForm(): FormGroup {
      return this._fb.group({
        id_releve_contact :  null,
        id_nomenclature_obs_meth: [null, Validators.required],
        id_nomenclature_obs_technique : [ null, Validators.required],
        id_nomenclature_bio_condition: [null, Validators.required],
        id_nomenclature_bio_status :  null,
        id_nomenclature_naturalness: null,
        id_nomenclature_exist_proof: null,
        id_nomenclature_valid_status: null,
        id_nomenclature_diffusion_level: null,
        id_validator: null,
        determiner: '',
        id_nomenclature_determination_method: null,
        determination_method_as_text: '',
        cd_nom: [ null, Validators.required],
        nom_cite: '',
        meta_v_taxref: 'Taxref V9.0',
        sample_number_proof: '',
        digital_proof: '',
        non_digital_proof: '',
        deleted: false,
        comment: '',
        cor_counting_contact: ''
      });
     }


   initCounting(): FormGroup {
      return this._fb.group({
        id_nomenclature_life_stage: [null, Validators.required],
        id_nomenclature_sex: [null, Validators.required],
        id_nomenclature_obj_count: [null, Validators.required],
        id_nomenclature_type_count: null,
        count_min : [null, Validators.compose([Validators.required, Validators.pattern('[1-9]+[0-9]*')])],
        count_max : [null, Validators.compose([Validators.required, Validators.pattern('[1-9]+[0-9]*')])],
      });
    }

  initCountingArray(data?: Array<any>): FormArray {
    // init the counting form with the data, or emty
    const arrayForm = this._fb.array([]);

    if (data) {
      for (let i = 0; i < data.length; i++) {
        const counting = this.initCounting();
        counting.patchValue(data[i]);
        arrayForm.push(counting);
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
    countingForm.removeAt(index);
    countingForm.value.splice(index, 1);
    this.nbCounting.splice(index, 1);

  }

  addOccurrence(index) {
    // push the counting
    this.occurrenceForm.controls.cor_counting_contact.patchValue(this.countingForm.value);
    // format the taxon
    this.occurrenceForm.value.cd_nom = this.occurrenceForm.value.cd_nom.cd_nom;
    // push or update the occurrence
    if (this.releveForm.value.properties.t_occurrences_contact.length === this.indexOccurrence) {
      // push the current taxon in the taxon list and refresh the currentTaxon
      this.taxonsList.push(this.currentTaxon);
      this.releveForm.value.properties.t_occurrences_contact.push(this.occurrenceForm.value);
    }else {
      this.taxonsList.splice(index, 0, this.currentTaxon);
      this.releveForm.value.properties.t_occurrences_contact[this.indexOccurrence] = this.occurrenceForm.value;
    }
    // set occurrence index
    this.indexOccurrence = this.releveForm.value.properties.t_occurrences_contact.length;
    // reset counting
    this.nbCounting = [''];
    this.indexCounting = 0;
    // reset current taxon
    this.currentTaxon = {};
    // reset occurrence form
    this.occurrenceForm = this.initOccurrenceForm();
    // reset the counting
    this.countingForm = this.initCountingArray();
    this.showOccurrence = false;
    this.isEdintingOccurrence = false;
  }

  editOccurence(index) {
    // set editing occurrence to true
    this.isEdintingOccurrence = true;
    // set showOccurrence to true
    this.showOccurrence = true;
    this.taxonsList.splice(index, 1);
    // set the current index
    this.indexOccurrence = index;
    // get the occurrence data from releve form
    const occurenceData = this.releveForm.value.properties.t_occurrences_contact[index];
    const countingData = occurenceData.cor_counting_contact;
    const nbCounting = countingData.length;
    // load the taxons info
    this._dfs.getTaxonInfo(occurenceData.cd_nom)
      .subscribe(taxon => {
        occurenceData['cd_nom'] = {
          'cd_nom': taxon.cd_nom,
          'group2_inpn': taxon.group2_inpn,
          'lb_nom': taxon.lb_nom,
          'nom_valide': taxon.nom_valide,
          'regne': taxon.regne,
        };
        // init occurence form with the data to edit
        this.occurrenceForm.patchValue(occurenceData);
        // set the current taxon
        this.currentTaxon = occurenceData.cd_nom;
      });
    // init the counting form with the data to edit
    for (let i = 1; i < nbCounting; i++) {
      this.nbCounting.push('');
     }
     this.countingForm.patchValue(countingData);

  }

  toggleOccurrence() {
    this.showOccurrence = !this.showOccurrence;
  }

  removeOneOccurrence(index) {
    this.taxonsList.splice(index, 1);
    this.releveForm.value.properties.t_occurrences_contact.splice(index, 1);
    this.indexOccurrence = this.indexOccurrence - 1 ;
  }

  updateTaxon(taxon) {
     this.currentTaxon = taxon;
   }

  formatObservers(observers) {
    const observersTab = [];
    observers.forEach(observer => {
      observer['nom_complet'] = observer.nom_role + ' ' + observer.prenom_role;
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

  onEditReleve(id) {
    this._router.navigate(['occtax/form', id]);
  }
  backToList() {
    this._router.navigate(['occtax']);
  }


}