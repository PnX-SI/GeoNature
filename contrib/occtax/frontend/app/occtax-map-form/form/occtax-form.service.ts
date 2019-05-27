import { Injectable } from "@angular/core";
import {
  FormBuilder,
  FormGroup,
  FormArray,
  Validators,
  AbstractControl,
  FormControl
} from "@angular/forms";
import { GeoJSON } from "leaflet";

import { AppConfig } from "@geonature_config/app.config";
import { HttpClient, HttpParams } from "@angular/common/http";
import { Router } from "@angular/router";
import { ModuleConfig } from "../../module.config";
import { AuthService, User } from "@geonature/components/auth/auth.service";
import { FormService } from "@geonature_common/form/form.service";
import { Taxon } from "@geonature_common/form/taxonomy/taxonomy.component";
import { CommonService } from "@geonature_common/service/common.service";

@Injectable()
export class OcctaxFormService {
  public markerCoordinates: Array<any>;
  public geojsonCoordinates: GeoJSON;
  public currentTaxon: Taxon;
  public indexCounting: number;
  public nbCounting: Array<string>;
  public indexOccurrence: number = 0;
  public taxonsList: Array<Taxon> = [];
  public showOccurrence: boolean;
  public showCounting: boolean;
  public editionMode: boolean;
  public isEdintingOccurrence: boolean;
  public defaultValues: any;
  public defaultValuesLoaded = false;
  public lastSubmitedOccurrence: any;
  public userReleveRigth: any;
  public savedOccurrenceData: any;
  public savedCurrentTaxon: any;
  public currentHourMax: string;

  public releveForm: FormGroup;
  public occurrenceForm: FormGroup;
  public countingForm: FormArray;
  public currentUser: User;
  public disabled = true;
  public stayOnFormInterface = new FormControl(false);

  constructor(
    private _fb: FormBuilder,
    private _http: HttpClient,
    private _router: Router,
    private _auth: AuthService,
    private _formService: FormService,
    private _commonService: CommonService
  ) {
    this.currentTaxon = {};
    this.indexCounting = 0;
    this.nbCounting = [""];
    this.showOccurrence = false;
    this.showCounting = false;
    this.isEdintingOccurrence = false;
    this.currentHourMax = null;

    this._router.events.subscribe(value => {
      this.isEdintingOccurrence = false;
    });
    this.currentUser = this._auth.getCurrentUser();
  } // end constructor

  getDefaultValues(idOrg?: number, regne?: string, group2_inpn?: string) {
    let params = new HttpParams();
    if (idOrg) {
      params = params.set("organism", idOrg.toString());
    }
    if (group2_inpn) {
      params = params.append("regne", regne);
    }
    if (regne) {
      params = params.append("group2_inpn", group2_inpn);
    }
    return this._http.get<any>(
      `${AppConfig.API_ENDPOINT}/occtax/defaultNomenclatures`,
      {
        params: params
      }
    );
  }

  initReleveForm(): FormGroup {
    const releveForm = this._fb.group({
      geometry: [null, Validators.required],
      properties: this._fb.group({
        id_releve_occtax: null,
        id_dataset: [null, Validators.required],
        id_digitiser: null,
        date_min: [null, Validators.required],
        date_max: [null, Validators.required],
        hour_min: [
          null,
          Validators.pattern(
            "^([0-9]|0[0-9]|1[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$"
          )
        ],
        hour_max: [
          null,
          Validators.pattern(
            "^([0-9]|0[0-9]|1[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$"
          )
        ],
        altitude_min: null,
        altitude_max: null,
        meta_device_entry: "web",
        comment: null,
        id_nomenclature_obs_technique: [null, Validators.required],
        observers: [
          null,
          !ModuleConfig.observers_txt ? Validators.required : null
        ],
        observers_txt: [
          null,
          ModuleConfig.observers_txt ? Validators.required : null
        ],
        id_nomenclature_grp_typ: null,
        t_occurrences_occtax: [new Array()]
      })
    });
    // validtors on date and hours
    releveForm.setValidators([
      this._formService.dateValidator(
        (releveForm.controls.properties as FormGroup).get("date_min"),
        (releveForm.controls.properties as FormGroup).get("date_max")
      ),
      this._formService.hourAndDateValidator(
        (releveForm.controls.properties as FormGroup).get("date_min"),
        (releveForm.controls.properties as FormGroup).get("date_max"),
        (releveForm.controls.properties as FormGroup).get("hour_min"),
        (releveForm.controls.properties as FormGroup).get("hour_max")
      ),
      this._formService.altitudeValidator(
        (releveForm.controls.properties as FormGroup).get("altitude_min"),
        (releveForm.controls.properties as FormGroup).get("altitude_max")
      )
    ]);
    return releveForm;
  }

  initOccurenceForm(): FormGroup {
    const occForm = this._fb.group({
      id_releve_occtax: null,
      id_occurrence_occtax: null,
      id_nomenclature_obs_meth: [null, Validators.required],
      id_nomenclature_bio_condition: [null, Validators.required],
      id_nomenclature_bio_status: null,
      id_nomenclature_naturalness: null,
      id_nomenclature_exist_proof: null,
      id_nomenclature_observation_status: null,
      id_nomenclature_diffusion_level: null,
      id_nomenclature_blurring: null,
      id_nomenclature_source_status: null,
      determiner: null,
      id_nomenclature_determination_method: null,
      cd_nom: null,
      nom_cite: null,
      meta_v_taxref: null,
      sample_number_proof: null,
      digital_proof: [{ value: null, disabled: true }],
      non_digital_proof: [{ value: null, disabled: true }],
      comment: null,
      cor_counting_occtax: ""
    });

    occForm.controls.cd_nom.setValidators([
      this._formService.taxonValidator,
      Validators.required
    ]);

    return occForm;
  }

  initCounting(): FormGroup {
    const countForm = this._fb.group({
      id_counting_occtax: null,
      id_nomenclature_life_stage: [null, Validators.required],
      id_nomenclature_sex: [null, Validators.required],
      id_nomenclature_obj_count: [null, Validators.required],
      id_nomenclature_type_count: null,
      id_occurrence_occtax: null,
      count_min: [
        1,
        Validators.compose([
          Validators.required,
          Validators.pattern("[0-9]+[0-9]*")
        ])
      ],
      count_max: [
        1,
        Validators.compose([
          Validators.required,
          Validators.pattern("[0-9]+[0-9]*")
        ])
      ]
    });
    countForm.setValidators([this.countingValidator]);
    return countForm;
  }

  countingValidator(countForm: AbstractControl): { [key: string]: boolean } {
    const countMin = countForm.get("count_min").value;
    const countMax = countForm.get("count_max").value;
    if (countMin && countMax) {
      return countMin > countMax ? { invalidCount: true } : null;
    }
    return null;
  }

  initCountingArray(data?): FormArray {
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

  addCounting() {
    this.indexCounting += 1;
    this.nbCounting.push("");
    const nextCounting = this.initCounting();
    this.patchDefaultNomenclatureCounting(nextCounting, this.defaultValues);
    this.countingForm.push(nextCounting);
  }

  removeCounting(index: number) {
    this.countingForm.removeAt(index);
    this.nbCounting.splice(index, 1);
    this.indexCounting -= 1;
  }

  addOccurrence(index, cancel?: boolean) {
    // Add the current occurrence in releve form or the saved occurrence if cancel
    // push the counting
    this.occurrenceForm.controls.cor_counting_occtax.patchValue(
      this.countingForm.value
    );
    // format the taxon
    this.occurrenceForm.value.cd_nom = this.occurrenceForm.value.cd_nom.cd_nom;
    // push or update the occurrence
    if (
      this.releveForm.value.properties.t_occurrences_occtax.length ===
      this.indexOccurrence
    ) {
      // push the current taxon in the taxon list
      this.taxonsList.push(this.currentTaxon);
      this.releveForm.value.properties.t_occurrences_occtax.push(
        this.occurrenceForm.value
      );
    } else {
      if (cancel) {
        // push the saved occurrence
        this.releveForm.value.properties.t_occurrences_occtax[
          this.indexOccurrence
        ] = this.savedOccurrenceData;
        this.taxonsList.splice(index, 0, this.savedCurrentTaxon);
      } else {
        this.releveForm.value.properties.t_occurrences_occtax[
          this.indexOccurrence
        ] = this.occurrenceForm.value;
        this.taxonsList.splice(index, 0, this.currentTaxon);
      }
    }
    // set occurrence index
    this.indexOccurrence = this.releveForm.value.properties.t_occurrences_occtax.length;
    // reset counting
    this.nbCounting = [""];
    this.indexCounting = 0;
    // reset current taxon
    this.currentTaxon = {};
    // reset occurrence form
    this.occurrenceForm = this.initOccurenceForm();
    this.patchDefaultNomenclatureOccurrence(this.defaultValues);

    // reset the counting
    this.countingForm = this.initCountingArray();
    this.patchDefaultNomenclatureCounting(
      this.countingForm.controls[0] as FormGroup,
      this.defaultValues
    );
    this.showOccurrence = false;
    this.isEdintingOccurrence = false;
  }

  cancelOccurrence() {
    // if occurrence is currently editing, save former occurrence
    if (this.isEdintingOccurrence) {
      this.addOccurrence(this.indexOccurrence, true);
      // else refresh occurrence form
    } else {
      this.occurrenceForm = this.initOccurenceForm();
      this.patchDefaultNomenclatureOccurrence(this.defaultValues);
    }
    this.isEdintingOccurrence = false;
  }

  editOccurence(index) {
    // set editing occurrence to true
    this.isEdintingOccurrence = true;
    // set showOccurrence to true
    this.showOccurrence = true;
    const currentEditedTaxon = this.taxonsList.splice(index, 1)[0];
    // set the current index
    this.indexOccurrence = index;
    // get the occurrence data from releve form
    const occurenceData = this.releveForm.value.properties.t_occurrences_occtax[
      index
    ];
    this.savedOccurrenceData = Object.assign(
      {},
      this.releveForm.value.properties.t_occurrences_occtax[index]
    );

    const countingData = occurenceData.cor_counting_occtax;
    const nbCounting = countingData.length;
    this.currentTaxon = currentEditedTaxon;
    // patch occurrence data
    occurenceData["cd_nom"] = currentEditedTaxon;
    this.occurrenceForm.patchValue(occurenceData);
    this.savedCurrentTaxon = currentEditedTaxon;
    // init the counting form with the data to edit
    for (let i = 1; i < nbCounting; i++) {
      this.nbCounting.push("");
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
    this.releveForm.value.properties.t_occurrences_occtax.splice(index, 1);
    this.indexOccurrence = this.indexOccurrence - 1;
  }

  patchDefaultNomenclatureReleve(defaultNomenclatures): void {
    this.releveForm.controls.properties.patchValue({
      id_nomenclature_grp_typ: defaultNomenclatures["TYP_GRP"],
      id_nomenclature_obs_technique: defaultNomenclatures["TECHNIQUE_OBS"]
    });
  }

  patchDefaultNomenclatureOccurrence(defaultNomenclatures): void {
    this.occurrenceForm.patchValue({
      id_nomenclature_bio_condition: defaultNomenclatures["ETA_BIO"],
      id_nomenclature_naturalness: defaultNomenclatures["NATURALITE"],
      id_nomenclature_obs_meth: defaultNomenclatures["METH_OBS"],
      id_nomenclature_bio_status: defaultNomenclatures["STATUT_BIO"],
      id_nomenclature_exist_proof: defaultNomenclatures["PREUVE_EXIST"],
      id_nomenclature_determination_method:
        defaultNomenclatures["METH_DETERMIN"],
      id_nomenclature_observation_status: defaultNomenclatures["STATUT_OBS"],
      id_nomenclature_diffusion_level: defaultNomenclatures["NIV_PRECIS"],
      id_nomenclature_blurring: defaultNomenclatures["DEE_FLOU"],
      id_nomenclature_source_status: defaultNomenclatures["STATUT_SOURCE"]
    });
  }

  patchDefaultNomenclatureCounting(
    countingForm: FormGroup,
    defaultNomenclatures
  ): void {
    countingForm.patchValue({
      id_nomenclature_life_stage: defaultNomenclatures["STADE_VIE"],
      id_nomenclature_sex: defaultNomenclatures["SEXE"],
      id_nomenclature_obj_count: defaultNomenclatures["OBJ_DENBR"],
      id_nomenclature_type_count: defaultNomenclatures["TYP_DENBR"],
      id_nomenclature_valid_status: defaultNomenclatures["STATUT_VALID"]
    });
  }

  patchAllDefaultNomenclature() {
    // fetch and patch all default nomenclature
    this.getDefaultValues(this.currentUser.id_organisme).subscribe(data => {
      this.defaultValues = data;
      this.patchDefaultNomenclatureReleve(data);
      this.patchDefaultNomenclatureOccurrence(data);
      this.patchDefaultNomenclatureCounting(
        this.countingForm.controls[0] as FormGroup,
        data
      );
    });
  }

  onTaxonChanged($event) {
    this.currentTaxon = $event.item;
    // set 'nom_cite'
    this.occurrenceForm.patchValue({ nom_cite: $event.item.search_name });
    // fetch default nomenclature value filtered by organism, regne, group2_inpn
    this.getDefaultValues(
      this.currentUser.id_organisme,
      $event.item.regne,
      $event.item.group2_inpn
    ).subscribe(data => {
      // occurrence
      this.patchDefaultNomenclatureOccurrence(data);
      // counting
      this.countingForm.controls.forEach(formgroup => {
        this.patchDefaultNomenclatureCounting(formgroup as FormGroup, data);
      });
    });
  }

  formatObservers(observers) {
    const observersTab = [];
    observers.forEach(observer => {
      observer["nom_complet"] = observer.nom_role + " " + observer.prenom_role;
      observersTab.push(observer);
    });
    return observersTab;
  }

  formatDate(strDate) {
    const date = new Date(strDate);
    return {
      year: date.getFullYear(),
      month: date.getMonth() + 1,
      day: date.getDate()
    };
  }

  onEditReleve(id) {
    this._router.navigate(["occtax/form", id]);
  }
  backToList() {
    this._router.navigate(["occtax"]);
  }

  formDisabled() {
    if (this.disabled) {
      this._commonService.translateToaster(
        "warning",
        "Releve.FillGeometryFirst"
      );
    }
  }
}
