import { Injectable } from '@angular/core';
import { FormControl, FormBuilder, FormGroup, FormArray, Validators } from '@angular/forms';
import { AppConfig } from '../../../../conf/app.config';
import { HttpClient, HttpParams } from '@angular/common/http';
import { DataFormService } from '../../../../core/GN2Common/form/data-form.service';
import { ActivatedRoute, Router } from '@angular/router';
import { ContactConfig } from '../../contact.config';
import { AuthService, User } from '../../../../core/components/auth/auth.service';


@Injectable()
export class ContactFormService {
  public currentTaxon: any;
  public indexCounting: number;
  public nbCounting: Array<string>;
  public indexOccurrence: number = 0;
  public taxonsList = [];
  public showOccurrence: boolean;
  public showCounting: boolean;
  public editionMode: boolean;
  public isEdintingOccurrence: boolean;
  public defaultValues: any;
  public defaultValuesLoaded = false;
  public lastSubmitedOccurrence: any;

  public releveForm: FormGroup;
  public occurrenceForm: FormGroup;
  public countingForm: FormArray;
  public currentUser: User;

  constructor(private _fb: FormBuilder, private _http: HttpClient, private _dfs: DataFormService, private _router: Router,
      private _auth: AuthService) {
    this.currentTaxon = {};
    this.indexCounting = 0;
    this.nbCounting = [''];
    this.showOccurrence = false;
    this.showCounting = false;
    this.isEdintingOccurrence = false;

    this._router.events.subscribe(value => {
      this.isEdintingOccurrence = false;
    });
    this.currentUser = this._auth.getCurrentUser();

   }// end constructor


   getDefaultValues(idOrg?: number, regne?: string, group2_inpn?: string) {
     let params = new HttpParams();
     params = params.set('organism', idOrg.toString());
     if (group2_inpn) {
      params = params.append('regne', regne);
     }
     if (regne) {
      params = params.append('group2_inpn', group2_inpn);
     }
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}contact/defaultNomenclatures`, {params: params});
   }

   initObservationForm(): FormGroup {
    return this._fb.group({
      geometry: [null, Validators.required],
      properties: this._fb.group({
        id_releve_contact : null,
        id_dataset: [null, Validators.required],
        id_digitiser : this.currentUser.userId,
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

   initOccurrenceFormDefaultValues(): FormGroup {
      return this._fb.group({
        id_releve_contact :  null,
        id_nomenclature_obs_meth: [this.defaultValues[14], Validators.required],
        id_nomenclature_bio_condition: [this.defaultValues[7], Validators.required],
        id_nomenclature_bio_status : this.defaultValues[13],
        id_nomenclature_naturalness: this.defaultValues[8],
        id_nomenclature_exist_proof: this.defaultValues[15],
        id_nomenclature_observation_status : this.defaultValues[18],
        id_nomenclature_valid_status: this.defaultValues[101],
        id_nomenclature_diffusion_level: this.defaultValues[5],
        id_nomenclature_blurring: this.defaultValues[4],
        id_validator: null,
        determiner: null,
        id_nomenclature_determination_method: this.defaultValues[106],
        determination_method_as_text: '',
        cd_nom: [ null, Validators.required],
        nom_cite: null,
        meta_v_taxref: 'Taxref V9.0',
        sample_number_proof: null,
        digital_proof: null,
        non_digital_proof: null,
        deleted: false,
        comment: null,
        cor_counting_contact: ''
      });
     }
     initOccurenceForm(): FormGroup {
      return this._fb.group({
        id_releve_contact :  null,
        id_nomenclature_obs_meth: [null, Validators.required],
        id_nomenclature_bio_condition: [null, Validators.required],
        id_nomenclature_bio_status : null,
        id_nomenclature_naturalness: null,
        id_nomenclature_exist_proof: null,
        id_nomenclature_observation_status : null,
        id_nomenclature_valid_status: null,
        id_nomenclature_diffusion_level: null,
        id_nomenclature_blurring: null,
        id_validator: null,
        determiner: null,
        id_nomenclature_determination_method: null,
        determination_method_as_text: '',
        cd_nom: [null, Validators.required],
        nom_cite: null,
        meta_v_taxref: 'Taxref V9.0',
        sample_number_proof: null,
        digital_proof: null,
        non_digital_proof: null,
        deleted: false,
        comment: null,
        cor_counting_contact: ''
      });
     }

   initCountingDefaultValues(): FormGroup {
      return this._fb.group({
        id_nomenclature_life_stage: [this.defaultValues[10], Validators.required],
        id_nomenclature_sex: [this.defaultValues[9], Validators.required],
        id_nomenclature_obj_count: [this.defaultValues[6], Validators.required],
        id_nomenclature_type_count: this.defaultValues[21],
        count_min : [1, Validators.compose([Validators.required, Validators.pattern('[1-9]+[0-9]*')])],
        count_max : [1, Validators.compose([Validators.required, Validators.pattern('[1-9]+[0-9]*')])],
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


  initCountingArrayDefaultValues(data?: Array<any>): FormArray {
    // init the counting form with the data, or empty
    const arrayForm = this._fb.array([]);
    if (data) {
      for (let i = 0; i < data.length; i++) {
        const counting = this.initCountingDefaultValues();
        counting.patchValue(data[i]);
        arrayForm.push(counting);
      }
    } else {
      const counting = this.initCountingDefaultValues();
      arrayForm.push(counting);
    }
    return arrayForm;
  }

  initCountingArray(data): FormArray {
    // init the counting form with the data, or empty
    const arrayForm = this._fb.array([]);
    if (data) {
      for (let i = 0; i < data.length; i++) {
        const counting = this.initCounting();
        counting.patchValue(data[i]);
        arrayForm.push(counting);
      }
    } else {
      const counting = this.initCounting();
      arrayForm.push(counting);
    }
    return arrayForm;
  }

  initFormsWithDefaultValues() {
    this.getDefaultValues(this.currentUser.organismId)
    .subscribe(res => {
      this.defaultValues = res;
      this.defaultValuesLoaded = true;
      // init the forms with default values
      this.releveForm = this.initObservationForm();
      this.occurrenceForm = this.initOccurrenceFormDefaultValues();
      this.countingForm = this.initCountingArrayDefaultValues();
    } );
  }


  addCounting() {
    this.indexCounting += 1;
    this.nbCounting.push('');
    const countingCtrl = this.initCountingDefaultValues();
    this.countingForm.push(countingCtrl);
    }

  removeCounting(index: number) {
    this.countingForm.removeAt(index);
    this.nbCounting.splice(index, 1);
    this.indexCounting -= 1;

  }

  addOccurrence(index) {
    // save the last Occurrence
    
    this.lastSubmitedOccurrence = this.occurrenceForm.value;
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
    this.occurrenceForm = this.initOccurrenceFormDefaultValues();
    // path the value I want to persist
    this.occurrenceForm.patchValue({
      'id_nomenclature_obs_meth': this.lastSubmitedOccurrence.id_nomenclature_obs_meth,
      'id_nomenclature_bio_condition': this.lastSubmitedOccurrence.id_nomenclature_bio_condition
    });
    // reset the counting
    this.countingForm = this.initCountingArrayDefaultValues();
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
     this.countingForm = this.initCountingArray(countingData);
  }

  toggleOccurrence() {
    this.showOccurrence = !this.showOccurrence;
  }

  toggleCounting() {
    this.showCounting = !this.showCounting;
  }

  removeOneOccurrence(index) {
    this.taxonsList.splice(index, 1);
    this.releveForm.value.properties.t_occurrences_contact.splice(index, 1);
    this.indexOccurrence = this.indexOccurrence - 1 ;
  }

  onTaxonChanged(taxon) {
     this.currentTaxon = taxon;
     // fetch default nomenclature value filtered by organism, regne, group2_inpn
     this.getDefaultValues(this.currentUser.organismId, taxon.regne, taxon.group2_inpn)
       .subscribe(data => {
         this.occurrenceForm.patchValue({
          id_nomenclature_bio_condition: data[7],
          id_nomenclature_naturalness : data[8],
          id_nomenclature_obs_meth: data[14],
          id_nomenclature_bio_status: data[13],
          id_nomenclature_exist_proof : data[15],
          id_nomenclature_determination_method: data[106],
         });

         // sexe : 9
       });


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