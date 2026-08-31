import { Injectable } from "@angular/core";
import {
  UntypedFormBuilder,
  UntypedFormGroup,
  UntypedFormControl,
  Validators,
  AbstractControl,
  UntypedFormArray,
} from "@angular/forms";
import { NgbDateParserFormatter } from "@ng-bootstrap/ng-bootstrap";
import { FormService } from "@geonature_common/form/form.service";
import { DataFormService } from "@geonature_common/form/data-form.service";
import { OcchabStoreService } from "./store.service";
import { ConfigService } from "@geonature/services/config.service";
import { Station, StationFeature } from "../models";

@Injectable()
export class OcchabFormService {
  public stationForm: UntypedFormGroup;
  public typoHabControl = new UntypedFormControl();
  public selectedTypo: any;
  public currentEditingHabForm = null;
  public currentHabCopy = null;
  /** Définitions des champs additionnels passées au générateur de formulaire dynamique */
  public stationAdditionalFieldsDef: Array<any> = [];
  public currentHabAdditionalFieldsDef: Array<any> = [];
  /** Définitions brutes, telles que renvoyées par l'API */
  private _rawStationDefs: Array<any> = [];
  private _rawHabitatDefs: Array<any> = [];
  /** additional_data de la station en cours d'édition, le temps que les définitions arrivent */
  private _stationAdditionalData = null;
  constructor(
    private _fb: UntypedFormBuilder,
    private _dateParser: NgbDateParserFormatter,
    private _gn_dataSerice: DataFormService,
    private _storeService: OcchabStoreService,
    private _formService: FormService,
    public config: ConfigService
  ) {
    // get selected cd_typo to filter the habref autcomplete
    this.typoHabControl.valueChanges.subscribe((data) => {
      this.selectedTypo = { cd_typo: data };
    });
    // les définitions et la station éditée arrivent dans un ordre non garanti :
    // chacune déclenche le recalcul de son côté
    this._storeService.stationAdditionalFields$.subscribe((defs) => {
      this._rawStationDefs = defs;
      this.refreshStationAdditionalFieldsDef();
    });
    this._storeService.habitatAdditionalFields$.subscribe((defs) => {
      this._rawHabitatDefs = defs;
      if (this.currentEditingHabForm !== null) {
        this.refreshCurrentHabAdditionalFieldsDef();
      }
    });
  }

  /**
   * Ne conserve que les champs globaux et ceux rattachés au jeu de données courant.
   * L'API renvoie les deux, le tri se fait ici pour rester réactif au changement de JDD
   * sans requête supplémentaire.
   */
  private filterByDataset(defs: Array<any>): Array<any> {
    const idDataset = this.stationForm
      ? this.stationForm.get("id_dataset").value
      : null;
    return (defs || []).filter(
      (def) =>
        !def.datasets ||
        def.datasets.length === 0 ||
        def.datasets.some((dataset) => dataset.id_dataset === idDataset)
    );
  }

  /**
   * Le générateur dynamique crée ses contrôles à partir de `def.value` et non de la
   * valeur du FormGroup : patcher un `fb.group({})` vide serait sans effet. On clone
   * donc les définitions en y injectant les valeurs — le clone fournit au passage la
   * nouvelle référence de tableau qui déclenche la reconstruction des contrôles.
   */
  private cloneDefsWithValues(defs: Array<any>, values: any): Array<any> {
    return this.filterByDataset(defs).map((def) => {
      const value = values ? values[def.attribut_name] : undefined;
      if (value === undefined || value === null) {
        return { ...def };
      }
      return {
        ...def,
        value:
          def.type_widget === "date" ? this._dateParser.parse(value) : value,
      };
    });
  }

  refreshStationAdditionalFieldsDef() {
    this.stationAdditionalFieldsDef = this.cloneDefsWithValues(
      this._rawStationDefs,
      this._stationAdditionalData
    );
  }

  private refreshCurrentHabAdditionalFieldsDef() {
    const habArrayForm = this.stationForm.controls.habitats as UntypedFormArray;
    const currentHab = habArrayForm.controls[this.currentEditingHabForm];
    this.currentHabAdditionalFieldsDef = this.cloneDefsWithValues(
      this._rawHabitatDefs,
      currentHab ? currentHab.value.additional_data : null
    );
  }

  /** Reformate les widgets date avant envoi au serveur */
  private formatAdditionalDataBeforePost(defs: Array<any>, data: any) {
    const formatedData = { ...(data || {}) };
    (defs || []).forEach((def) => {
      if (def.type_widget === "date" && formatedData[def.attribut_name]) {
        formatedData[def.attribut_name] = this._dateParser.format(
          formatedData[def.attribut_name]
        );
      }
    });
    return formatedData;
  }

  initStationForm(): UntypedFormGroup {
    const stationForm = this._fb.group({
      id_station: null,
      unique_id_sinp_station: null,
      id_dataset: [null, Validators.required],
      date_min: [null, Validators.required],
      date_max: [null, Validators.required],
      observers: [
        null,
        !this.config.OCCHAB.OBSERVER_AS_TXT ? Validators.required : null,
      ],
      observers_txt: [
        null,
        this.config.OCCHAB.OBSERVER_AS_TXT ? Validators.required : null,
      ],
      is_habitat_complex: false,
      id_nomenclature_exposure: null,
      altitude_min: null,
      altitude_max: null,
      depth_min: null,
      depth_max: null,
      area: null,
      id_nomenclature_area_surface_calculation: null,
      id_nomenclature_geographic_object: [null, Validators.required],
      id_nomenclature_type_sol: null,
      geom_4326: [null, Validators.required],
      comment: null,
      additional_data: this._fb.group({}),
      habitats: this._fb.array([]),
    });
    // les champs additionnels peuvent être rattachés à un JDD : on rejoue le tri
    // à chaque changement de jeu de données
    stationForm.get("id_dataset").valueChanges.subscribe(() => {
      this.refreshStationAdditionalFieldsDef();
      if (this.currentEditingHabForm !== null) {
        this.refreshCurrentHabAdditionalFieldsDef();
      }
    });
    stationForm.setValidators([
      this._formService.dateValidator(
        stationForm.get("date_min"),
        stationForm.get("date_max")
      ),
      this._formService.minMaxValidator(
        stationForm.get("altitude_min"),
        stationForm.get("altitude_max"),
        "invalidAlt"
      ),
    ]);

    return stationForm;
  }

  patchDefaultNomenclaureStation(defaultNomenclature) {
    this.stationForm.patchValue({
      id_nomenclature_area_surface_calculation:
        defaultNomenclature["METHOD_CALCUL_SURFACE"],
      id_nomenclature_geographic_object: defaultNomenclature["NAT_OBJ_GEO"],
      id_nomenclature_type_sol: defaultNomenclature["TYPE_SOL"],
    });
  }

  initHabForm(defaultNomenclature): UntypedFormGroup {
    const habForm = this._fb.group({
      id_habitat: null,
      unique_id_sinp_hab: null,
      nom_cite: null,
      habref: [Validators.required, this.cdHabValidator],
      id_nomenclature_determination_type: defaultNomenclature
        ? defaultNomenclature["DETERMINATION_TYP_HAB"]
        : null,
      determiner: null,
      id_nomenclature_community_interest: null,
      id_nomenclature_collection_technique: [
        defaultNomenclature
          ? defaultNomenclature["TECHNIQUE_COLLECT_HAB"]
          : null,
        Validators.required,
      ],
      recovery_percentage: null,
      id_nomenclature_abundance: null,
      technical_precision: null,
      additional_data: this._fb.group({}),
    });
    habForm.setValidators([this.technicalValidator]);
    return habForm;
  }

  technicalValidator(habForm: AbstractControl): { [key: string]: boolean } {
    const technicalValue = habForm.get(
      "id_nomenclature_collection_technique"
    ).value;
    const technicalPrecision = habForm.get("technical_precision").value;

    if (
      technicalValue &&
      technicalValue.cd_nomenclature == "10" &&
      !technicalPrecision
    ) {
      return { invalidTechnicalValues: true };
    }
    return null;
  }

  cdHabValidator(habControl: AbstractControl) {
    const currentHab = habControl.value;
    if (!currentHab) {
      return null;
    } else if (!currentHab.cd_hab && !currentHab.search_name) {
      return {
        invalidTaxon: true,
      };
    } else {
      return null;
    }
  }

  resetAllForm() {
    this.stationForm.reset();
  }

  addNewHab() {
    const habFormArray = this.stationForm.controls.habitats as UntypedFormArray;
    habFormArray.insert(
      0,
      this.initHabForm(this._storeService.defaultNomenclature)
    );
    this.currentEditingHabForm = 0;
    this.currentHabCopy = null;
    this.refreshCurrentHabAdditionalFieldsDef();
  }

  /**
   * patch the hab with the data of station form and splice the station form with the given index
   * @param index: index of the habitat to edit
   */
  editHab(index) {
    const habArrayForm = this.stationForm.controls.habitats as UntypedFormArray;
    this.currentEditingHabForm = index;
    this.currentHabCopy = {
      ...habArrayForm.controls[this.currentEditingHabForm].value,
    };
    this.refreshCurrentHabAdditionalFieldsDef();
  }

  /** Cancel the current hab
   * if idEdition = true, we patch the former value to no not loose it
   * we keep the order
   */
  cancelHab() {
    if (this.currentEditingHabForm !== null) {
      const habArrayForm = this.stationForm.controls
        .habitats as UntypedFormArray;
      if (this.currentHabCopy === null)
        habArrayForm.removeAt(this.currentEditingHabForm);
      else {
        const habForm = habArrayForm.controls[
          this.currentEditingHabForm
        ] as UntypedFormGroup;
        this.restoreAdditionalDataShape(
          habForm.get("additional_data") as UntypedFormGroup,
          this.currentHabCopy.additional_data
        );
        habForm.setValue(this.currentHabCopy);
      }
      this.currentHabCopy = null;
      this.currentEditingHabForm = null;
      this.currentHabAdditionalFieldsDef = [];
    }
  }

  /**
   * Le générateur dynamique ajoute ses contrôles après la prise de la copie de
   * l'habitat : setValue échouerait sur les contrôles absents de cette copie.
   * On réaligne donc la forme du sous-groupe sur celle de la copie. Les contrôles
   * recréés ici n'ont pas de validateur, mais ils seront remplacés par ceux du
   * générateur à la prochaine édition de cet habitat.
   */
  private restoreAdditionalDataShape(
    additionalDataForm: UntypedFormGroup,
    previousValue: any
  ) {
    Object.keys(additionalDataForm.controls).forEach((name) =>
      additionalDataForm.removeControl(name, { emitEvent: false })
    );
    Object.keys(previousValue || {}).forEach((name) =>
      additionalDataForm.addControl(
        name,
        new UntypedFormControl(previousValue[name]),
        { emitEvent: false }
      )
    );
  }

  /**
   * Delete the current hab of the station form
   * @param index index of the habitat to delete
   */
  deleteHab(index) {
    const habArrayForm = this.stationForm.controls.habitats as UntypedFormArray;
    habArrayForm.removeAt(index);
  }

  patchGeoValue(geom) {
    this.stationForm.patchValue({ geom_4326: geom.geometry });
    this._gn_dataSerice.getAreaSize(geom).subscribe(
      (data) => {
        this.stationForm.patchValue({ area: Math.round(data) });
      },
      // if error reset area
      () => {
        this.stationForm.patchValue({ area: null });
      }
    );
    // this._gn_dataSerice.getGeoIntersection(geom).subscribe(data => {
    //   // TODO: areas intersected
    // });

    this._gn_dataSerice.getGeoInfo(geom).subscribe(
      (data) => {
        this.stationForm.patchValue({
          altitude_min: data["altitude"]["altitude_min"],
          altitude_max: data["altitude"]["altitude_max"],
        });
      },
      () => {
        this.stationForm.patchValue({
          altitude_min: null,
          altitude_max: null,
        });
      }
    );
  }

  patchNomCite($event) {
    const habArrayForm = this.stationForm.controls.habitats as UntypedFormArray;
    habArrayForm.controls[this.currentEditingHabForm].patchValue({
      nom_cite: $event.item.search_name,
    });
  }

  /**
   * Transform an nomenclature object to a simple integer taking the id_nomenclature
   * @param obj a dict with id_nomenclature key
   */
  formatNomenclature(obj) {
    Object.keys(obj).forEach((key) => {
      if (key.startsWith("id_nomenclature") && obj[key]) {
        obj[key] = obj[key].id_nomenclature;
      }
    });
  }

  getOrNull(obj, key) {
    return obj[key] ? obj[key] : null;
  }

  /**
   * format the data returned by get one station to fit with the form
   */
  formatStationAndHabtoPatch(station) {
    // me
    const formatedHabitats = station.habitats.map((hab) => {
      // hab.habref["search_name"] = hab.nom_cite;
      return {
        ...hab,
        id_nomenclature_determination_type: this.getOrNull(
          hab,
          "nomenclature_determination_type"
        ),
        id_nomenclature_collection_technique: this.getOrNull(
          hab,
          "nomenclature_collection_technique"
        ),
        id_nomenclature_abundance: this.getOrNull(
          hab,
          "nomenclature_abundance"
        ),
        id_nomenclature_community_interest: this.getOrNull(
          hab,
          "nomenclature_community_interest"
        ),
      };
    });
    station.habitats.forEach((hab, index) => {
      formatedHabitats[index]["habref"] = hab.habref || {};
      formatedHabitats[index]["habref"]["search_name"] = hab.nom_cite;
    });
    station["habitats"] = formatedHabitats;
    return {
      ...station,
      date_min: this._dateParser.parse(station.date_min),
      date_max: this._dateParser.parse(station.date_max),
      id_nomenclature_geographic_object: this.getOrNull(
        station,
        "nomenclature_geographic_object"
      ),
      id_nomenclature_area_surface_calculation: this.getOrNull(
        station,
        "nomenclature_area_surface_calculation"
      ),
      id_nomenclature_exposure: this.getOrNull(
        station,
        "nomenclature_exposure"
      ),
      id_nomenclature_type_sol: this.getOrNull(
        station,
        "nomenclature_type_sol"
      ),
    };
  }

  /**
   * Crée les contrôles d'un sous-groupe `additional_data` à partir des valeurs
   * enregistrées. Le générateur dynamique les recréera avec leurs validateurs
   * à l'affichage du niveau concerné, mais les valeurs doivent être présentes
   * dans le formulaire avant cela : un patchValue sur un groupe vide ne fait rien.
   */
  private presetAdditionalDataControls(
    additionalDataForm: UntypedFormGroup,
    values: any
  ) {
    Object.keys(values || {}).forEach((name) =>
      additionalDataForm.addControl(
        name,
        new UntypedFormControl(values[name]),
        { emitEvent: false }
      )
    );
  }

  patchStationForm(oneStation) {
    // create habitat formArray
    for (let i = 0; i < oneStation.properties.habitats.length; i++) {
      const habForm = this.initHabForm(this._storeService.defaultNomenclature);
      this.presetAdditionalDataControls(
        habForm.get("additional_data") as UntypedFormGroup,
        oneStation.properties.habitats[i].additional_data
      );
      (this.stationForm.controls.habitats as UntypedFormArray).push(habForm);
    }

    const formatedData = this.formatStationAndHabtoPatch(oneStation.properties);
    this.stationForm.patchValue(formatedData);
    this.stationForm.patchValue({
      observers: oneStation.properties.observers[0],
    });
    this.stationForm.patchValue({
      geom_4326: oneStation.geometry,
    });
    this.currentEditingHabForm = null;
    // les valeurs des champs additionnels sont portées par les définitions,
    // pas par le FormGroup (cf. cloneDefsWithValues)
    this._stationAdditionalData = oneStation.properties.additional_data || null;
    this.refreshStationAdditionalFieldsDef();
  }

  /** Format a station before post */
  formatStationBeforePost(): StationFeature {
    let formData = Object.assign({}, this.stationForm.value);
    let observers = formData.observers;
    if (observers == null) {
      formData.observers = [];
    }
    else {
      formData.observers = [observers];
    }

    //format cd_hab
    formData.habitats.forEach((element) => {
      if (element.habref) {
        element.cd_hab = element.habref.cd_hab;
        delete element["habref"];
      }
    });

    // format date
    formData.date_min = this._dateParser.format(formData.date_min);
    formData.date_max = this._dateParser.format(formData.date_max);
    // format stations nomenclatures
    this.formatNomenclature(formData);

    // format habitat nomenclatures

    formData.habitats.forEach((element) => {
      this.formatNomenclature(element);
    });

    // format additional fields (dates) for both levels
    formData.additional_data = this.formatAdditionalDataBeforePost(
      this._rawStationDefs,
      formData.additional_data
    );
    formData.habitats.forEach((element) => {
      element.additional_data = this.formatAdditionalDataBeforePost(
        this._rawHabitatDefs,
        element.additional_data
      );
    });

    // Format data in geojson
    const geom = formData["geom_4326"];
    delete formData["geom_4326"];
    return {
      type: "Feature",
      geometry: {
        ...geom,
      },
      properties: {
        ...formData,
      },
    };
  }
}
