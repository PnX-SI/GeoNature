import { Injectable } from '@angular/core';
import {
  UntypedFormBuilder,
  UntypedFormGroup,
  UntypedFormControl,
  Validators,
  AbstractControl,
  UntypedFormArray,
} from '@angular/forms';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';
import { FormService } from '@geonature_common/form/form.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { OcchabStoreService } from './store.service';
import { ConfigService } from '@geonature/services/config.service';
import { Station, StationFeature } from '../models';

@Injectable()
export class OcchabFormService {
  public stationForm: UntypedFormGroup;
  public typoHabControl = new UntypedFormControl();
  public selectedTypo: any;
  public currentEditingHabForm = null;
  public currentHabCopy = null;
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
  }

  initStationForm(): UntypedFormGroup {
    const stationForm = this._fb.group({
      id_station: null,
      unique_id_sinp_station: null,
      id_dataset: [null, Validators.required],
      date_min: [null, Validators.required],
      date_max: [null, Validators.required],
      observers: [null, !this.config.OCCHAB.OBSERVER_AS_TXT ? Validators.required : null],
      observers_txt: [null, this.config.OCCHAB.OBSERVER_AS_TXT ? Validators.required : null],
      is_habitat_complex: false,
      id_nomenclature_exposure: null,
      altitude_min: null,
      altitude_max: null,
      depth_min: null,
      depth_max: null,
      area: null,
      id_nomenclature_area_surface_calculation: null,
      id_nomenclature_geographic_object: [null, Validators.required],
      geom_4326: [null, Validators.required],
      comment: null,
      habitats: this._fb.array([]),
    });
    stationForm.setValidators([
      this._formService.dateValidator(stationForm.get('date_min'), stationForm.get('date_max')),
      this._formService.minMaxValidator(
        stationForm.get('altitude_min'),
        stationForm.get('altitude_max'),
        'invalidAlt'
      ),
    ]);

    return stationForm;
  }

  patchDefaultNomenclaureStation(defaultNomenclature) {
    this.stationForm.patchValue({
      id_nomenclature_area_surface_calculation: defaultNomenclature['METHOD_CALCUL_SURFACE'],
      id_nomenclature_geographic_object: defaultNomenclature['NAT_OBJ_GEO'],
    });
  }

  initHabForm(defaultNomenclature): UntypedFormGroup {
    const habForm = this._fb.group({
      id_habitat: null,
      unique_id_sinp_hab: null,
      nom_cite: null,
      habref: [Validators.required, this.cdHabValidator],
      id_nomenclature_determination_type: defaultNomenclature
        ? defaultNomenclature['DETERMINATION_TYP_HAB']
        : null,
      determiner: null,
      id_nomenclature_community_interest: null,
      id_nomenclature_collection_technique: [
        defaultNomenclature ? defaultNomenclature['TECHNIQUE_COLLECT_HAB'] : null,
        Validators.required,
      ],
      recovery_percentage: null,
      id_nomenclature_abundance: null,
      technical_precision: null,
    });
    habForm.setValidators([this.technicalValidator]);
    return habForm;
  }

  technicalValidator(habForm: AbstractControl): { [key: string]: boolean } {
    const technicalValue = habForm.get('id_nomenclature_collection_technique').value;
    const technicalPrecision = habForm.get('technical_precision').value;

    if (technicalValue && technicalValue.cd_nomenclature == '10' && !technicalPrecision) {
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
    const currentHabNumber = this.stationForm.value.habitats.length - 1;
    const habFormArray = this.stationForm.controls.habitats as UntypedFormArray;
    habFormArray.insert(0, this.initHabForm(this._storeService.defaultNomenclature));
    this.currentEditingHabForm = 0;
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
  }

  /** Cancel the current hab
   * if idEdition = true, we patch the former value to no not loose it
   * we keep the order
   */
  cancelHab() {
    if (this.currentEditingHabForm !== null) {
      const habArrayForm = this.stationForm.controls.habitats as UntypedFormArray;
      habArrayForm.controls[this.currentEditingHabForm].setValue(this.currentHabCopy);
      this.currentHabCopy = null;
      this.currentEditingHabForm = null;
    }
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
          altitude_min: data['altitude']['altitude_min'],
          altitude_max: data['altitude']['altitude_max'],
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
      if (key.startsWith('id_nomenclature') && obj[key]) {
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
          'nomenclature_determination_method'
        ),
        id_nomenclature_collection_technique: this.getOrNull(
          hab,
          'nomenclature_collection_technique'
        ),
        id_nomenclature_abundance: this.getOrNull(hab, 'nomenclature_abundance'),
      };
    });
    station.habitats.forEach((hab, index) => {
      formatedHabitats[index]['habref'] = hab.habref || {};
      formatedHabitats[index]['habref']['search_name'] = hab.nom_cite;
    });
    station['habitats'] = formatedHabitats;
    return {
      ...station,
      date_min: this._dateParser.parse(station.date_min),
      date_max: this._dateParser.parse(station.date_max),
      id_nomenclature_geographic_object: this.getOrNull(station, 'nomenclature_geographic_object'),
      id_nomenclature_area_surface_calculation: this.getOrNull(
        station,
        'nomenclature_area_surface_calculation'
      ),
      id_nomenclature_exposure: this.getOrNull(station, 'nomenclature_exposure'),
    };
  }

  patchStationForm(oneStation) {
    // create habitat formArray
    for (let i = 0; i < oneStation.properties.habitats.length; i++) {
      (this.stationForm.controls.habitats as UntypedFormArray).push(
        this.initHabForm(this._storeService.defaultNomenclature)
      );
    }

    const formatedData = this.formatStationAndHabtoPatch(oneStation.properties);
    this.stationForm.patchValue(formatedData);
    this.stationForm.patchValue({
      geom_4326: oneStation.geometry,
    });
    this.currentEditingHabForm = null;
  }

  /** Format a station before post */
  formatStationBeforePost(): StationFeature {
    let formData = Object.assign({}, this.stationForm.value);
    //format cd_hab
    formData.habitats.forEach((element) => {
      if (element.habref) {
        element.cd_hab = element.habref.cd_hab;
        delete element['habref'];
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

    // Format data in geojson
    const geom = formData['geom_4326'];
    delete formData['geom_4326'];
    return {
      type: 'Feature',
      geometry: {
        ...geom,
      },
      properties: {
        ...formData,
      },
    };
  }
}
