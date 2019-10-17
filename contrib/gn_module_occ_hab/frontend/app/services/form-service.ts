import { Injectable } from "@angular/core";
import {
  FormBuilder,
  FormGroup,
  FormControl,
  Validators
} from "@angular/forms";
import { NgbDateParserFormatter } from "@ng-bootstrap/ng-bootstrap";
import { OccHabDataService } from "../services/data.service";
import { CommonService } from "@geonature_common/service/common.service";
import { DataFormService } from "@geonature_common/form/data-form.service";

@Injectable()
export class OcchabFormService {
  public stationForm: FormGroup;
  public habitatForm: FormGroup;
  public typoHabControl = new FormControl();
  public selectedTypo: any;
  public height = "90vh";
  public MAP_SMALL_HEIGHT = "50vh";
  public MAP_FULL_HEIGHT = "90vh";

  constructor(
    private _fb: FormBuilder,
    private _dateParser: NgbDateParserFormatter,
    private _dataService: OccHabDataService,
    private _commonService: CommonService,
    private _gn_dataSerice: DataFormService
  ) {
    // get selected cd_typo to filter the habref autcomplete
    this.typoHabControl.valueChanges.subscribe(data => {
      this.selectedTypo = { cd_typo: data };
    });
    this.stationForm = this._fb.group({
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

    this.habitatForm = this._fb.group({
      unique_id_sinp_hab: null,
      nom_cite: "test",
      habitat_obj: null,
      id_nomenclature_determination_type: null,
      determiner: null,
      id_nomenclature_collection_technique: [null, Validators.required],
      recovery_percentage: null,
      id_nomenclature_abundance: null,
      technical_precision: null
    });
  }

  resetStationForm() {
    this.stationForm.reset();
    this.stationForm.patchValue({ t_habitats: [] });
  }

  addHabitat() {
    // resize the map
    this.height = this.MAP_SMALL_HEIGHT;
    // this.stationForm.patchValue({ habitats: this.habitatForm.value });
    this.stationForm.value.t_habitats.push(this.habitatForm.value);
    this.habitatForm.reset();
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
  formatStationAndHab(station) {
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
    console.log(formatedHabitats);

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
        "geographic_object"
      ),
      id_nomenclature_exposure: this.getOrNull(station, "exposure")
    };
  }

  patchStationForm(oneStation) {
    const formatedStation = this.stationForm.patchValue(
      this.formatStationAndHab(oneStation.properties)
    );
    this.stationForm.patchValue({
      geom_4326: oneStation.geometry
    });
  }

  postStation() {
    let formData = Object.assign({}, this.stationForm.value);

    //format cd_hab
    formData.t_habitats.forEach(element => {
      element.cd_hab = element.habitat_obj.cd_hab;
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

    this._dataService.postStation(formData).subscribe(
      data => {
        this.resetStationForm();
        this.habitatForm.reset();
        this.height = "65vh";
      },
      error => {
        if (error.status === 403) {
          this._commonService.translateToaster("error", "NotAllowed");
        } else {
          console.error(error.error.message);
          this._commonService.translateToaster("error", "ErrorMessage");
        }
      }
    );
  }
}
