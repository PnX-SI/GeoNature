import { Injectable } from "@angular/core";
import {
  FormBuilder,
  FormGroup,
  FormControl,
  Validators
} from "@angular/forms";
import { NgbDateParserFormatter } from "@ng-bootstrap/ng-bootstrap";
import { OccHabDataService } from "../services/data.service";
import { DataFormService } from "@geonature_common/form/data-form.service";

@Injectable()
export class OcchabFormService {
  public stationForm: FormGroup;
  public habitatForm: FormGroup;
  public typoHabControl = new FormControl();
  public selectedTypo: any;
  constructor(
    private _fb: FormBuilder,
    private _dateParser: NgbDateParserFormatter,
    private _gn_dataSerice: DataFormService
  ) {
    // get selected cd_typo to filter the habref autcomplete
    this.typoHabControl.valueChanges.subscribe(data => {
      this.selectedTypo = { cd_typo: data };
    });

    this.stationForm = this.initStationForm();
    this.habitatForm = this.initHabForm();
  }

  initStationForm(): FormGroup {
    return this._fb.group({
      id_station: null,
      unique_id_sinp_station: null,
      id_dataset: [null, Validators.required],
      date_min: [null, Validators.required],
      date_max: [null, Validators.required],
      observers: null,
      observers_txt: [null, Validators.required],
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
      t_habitats: [new Array()]
    });
  }

  initHabForm(): FormGroup {
    return this._fb.group({
      unique_id_sinp_hab: null,
      nom_cite: null,
      habref: null,
      id_nomenclature_determination_type: null,
      determiner: null,
      id_nomenclature_collection_technique: [null, Validators.required],
      recovery_percentage: null,
      id_nomenclature_abundance: null,
      technical_precision: null
    });
  }

  resetAllForm() {
    this.stationForm.reset();
    this.stationForm.patchValue({ t_habitats: [] });
    this.habitatForm.reset();
  }

  addHabitat() {
    // add at the beginning of the list
    this.stationForm.value.t_habitats.unshift(this.habitatForm.value);
    this.habitatForm.reset();
  }

  /**
   * patch the hab with the data of station form and splice the station form with the given index
   * @param index: index of the habitat to edit
   */
  editHab(index) {
    this.habitatForm.patchValue(this.stationForm.value.t_habitats[index]);
    // reproduce what the autocomplete component of habitat receive originaly
    this.habitatForm.patchValue({
      habref: {
        //nom_cite: this.stationForm.value.t_habitats[index].nom_cite,
        search_name: this.stationForm.value.t_habitats[index].nom_cite,
        cd_hab: this.stationForm.value.t_habitats[index].habref.cd_hab
      }
    });
    // remove the current hab and patch the form to fire events
    this.deleteHab(index);
  }

  /** Cancel the current hab
   * if idEdition = true, we patch the former value to no not loose it
   * we keep the order
   */
  cancelHab(isEditing?, currentIndex?) {
    if (isEditing) {
      this.stationForm.value.t_habitats.splice(
        currentIndex,
        0,
        this.habitatForm.value
      );
      this.stationForm.patchValue({
        t_habitats: this.stationForm.value.t_habitats
      });
    }
    this.habitatForm.reset();
  }

  /**
   * Delete the current hab of the station form
   * @param index index of the habitat to delete
   */
  deleteHab(index) {
    this.stationForm.value.t_habitats.splice(index, 1);
  }

  patchGeomValue(geom) {
    this.stationForm.patchValue({ geom_4326: geom.geometry });
    // this._gn_dataSerice.getAreaSize(geom).subscribe(data => {
    //   this.stationForm.patchValue({ area: Math.round(data) });
    // });
    this._gn_dataSerice.getGeoIntersection(geom).subscribe(data => {
      this.stationForm.patchValue({
        altitude_min: data["altitude_min"],
        altitude_max: data["altitude_max"]
      });
    });
  }

  patchNomCite($event) {
    this.habitatForm.patchValue({
      nom_cite: $event.item.search_name
    });
  }

  /**
   * Transform an nomenclature object to a simple integer taking the id_nomenclature
   * @param obj a dict with id_nomenclature key
   */
  formatNomenclature(obj) {
    Object.keys(obj).forEach(key => {
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
    const formatedHabitats = station.t_one_habitats.map(hab => {
      return {
        ...hab,
        id_nomenclature_determination_type: this.getOrNull(
          hab,
          "determination_method"
        ),
        id_nomenclature_collection_technique: this.getOrNull(
          hab,
          "collection_technique"
        ),
        id_nomenclature_abundance: this.getOrNull(hab, "abundance")
      };
    });
    station["t_habitats"] = formatedHabitats;

    return {
      ...station,
      date_min: this._dateParser.parse(station.date_min),
      date_max: this._dateParser.parse(station.date_max),
      id_nomenclature_geographic_object: this.getOrNull(
        station,
        "geographic_object"
      ),
      id_nomenclature_area_surface_calculation: this.getOrNull(
        station,
        "area_surface_calculation"
      ),
      id_nomenclature_exposure: this.getOrNull(station, "exposure")
    };
  }

  patchStationForm(oneStation) {
    const formatedData = this.formatStationAndHabtoPatch(oneStation.properties);

    this.stationForm.patchValue(formatedData);
    this.stationForm.controls.t_habitats.patchValue(formatedData.t_habitats);
    this.stationForm.patchValue({
      geom_4326: oneStation.geometry
    });
  }
  /** Format a station before post */
  formatStationBeforePost() {
    let formData = Object.assign({}, this.stationForm.value);

    //format cd_hab
    formData.t_habitats.forEach(element => {
      element.cd_hab = element.habref.cd_hab;
      delete element["habref"];
    });

    // format date
    formData.date_min = this._dateParser.format(formData.date_min);
    formData.date_max = this._dateParser.format(formData.date_max);
    // format stations nomenclatures
    this.formatNomenclature(formData);

    // format habitat nomenclatures

    formData.t_habitats.forEach(element => {
      this.formatNomenclature(element);
    });

    return formData;
  }
}
