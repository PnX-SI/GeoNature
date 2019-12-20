import { Component, OnInit } from "@angular/core";
import { CommonService } from "@geonature_common/service/common.service";
import { NgbDateParserFormatter } from "@ng-bootstrap/ng-bootstrap";
import { OcctaxFormService } from "./occtax-form.service";
import { Router } from "@angular/router";
import * as L from "leaflet";
import { OcctaxDataService } from "../../services/occtax-data.service";
import { MapService } from "@geonature_common/map/map.service";

@Component({
  selector: "pnx-occtax-form",
  templateUrl: "./occtax-form.component.html",
  styleUrls: ["./occtax-form.component.scss"],
  providers: []
})
export class OcctaxFormComponent implements OnInit {
  public disabledAfterPost = false;

  constructor(
    public fs: OcctaxFormService,
    private _dateParser: NgbDateParserFormatter,
    private _cfs: OcctaxDataService,
    private router: Router,
    private _commonService: CommonService,
    private _mapService: MapService
  ) {}

  ngOnInit() {
    // set show occurrence to false:
    this.fs.showOccurrence = false;
    // reset taxon list of service
    this.fs.taxonsList = [];
    this.fs.indexOccurrence = 0;
    this.fs.editionMode = false;
    // remove disabled form on geom selected
    this.fs.releveForm.controls.geometry.valueChanges.subscribe(data => {
      this.fs.disabled = false;
    });
  } // end ngOnInit

  formDisabled() {
    if (this.fs.disabled) {
      this._commonService.translateToaster(
        "warning",
        "Releve.FillGeometryFirst"
      );
    }
  }

  submitData() {
    // set the releveForm
    // copy the form value without reference
    const finalForm = JSON.parse(JSON.stringify(this.fs.releveForm.value));
    // format date
    const saveForm = JSON.parse(JSON.stringify(this.fs.releveForm.value));
    finalForm.properties.date_min = this._dateParser.format(
      finalForm.properties.date_min
    );
    finalForm.properties.date_max = this._dateParser.format(
      finalForm.properties.date_max
    );
    // set hour_min/hour_max to null
    if (
      finalForm.properties.hour_min &&
      finalForm.properties.hour_min.length == 0
    ) {
      finalForm.properties.hour_min = null;
    }
    if (
      finalForm.properties.hour_max &&
      finalForm.properties.hour_max.length == 0
    ) {
      finalForm.properties.hour_max = null;
    }
    // format nom_cite, update date, set id_releve_occtax and id_occurrence_occtax
    finalForm.properties.t_occurrences_occtax.forEach((occ, index) => {
      occ.id_releve_occtax = finalForm.properties.id_releve_occtax;
      occ.cor_counting_occtax.forEach(count => {
        count.id_occurrence_occtax = occ.id_occurrence_occtax;
      });
    });
    // format observers
    if (
      finalForm.properties.observers &&
      finalForm.properties.observers.length > 0
    ) {
      finalForm.properties.observers = finalForm.properties.observers.map(
        observer => observer.id_role
      );
    }
    // disable button
    this.disabledAfterPost = true;
    //console.log(JSON.stringify(finalForm));

    // Post
    this._cfs.postOcctax(finalForm).subscribe(
      () => {
        this.disabledAfterPost = false;
        this._commonService.translateToaster("success", "Relevé enregistré");
        // resert the forms
        this.fs.releveForm.reset();
        this.fs.patchDefaultNomenclatureOccurrence(this.fs.defaultValues);

        // reset the service value
        this.fs.taxonsList = [];
        this.fs.indexOccurrence = 0;
        this.fs.disabled = true;
        this.fs.showCounting = false;
        this.fs.currentHourMax = null;
        if (this.fs.stayOnFormInterface.value) {
          // prefil the form with the previous releve
          delete saveForm["geometry"];
          saveForm["properties"]["t_occurrences_occtax"] = [];
          // delete comment input
          delete saveForm["properties"]["comment"];
          saveForm["properties"]["t_occurrences_occtax"] = [];
          this.fs.releveForm.patchValue(saveForm);
        } else {
          // redirect
          this.router.navigate(["/occtax"]);
        }
        // reset carto
        this._mapService.setEditingMarker(false);
        // reset default marker mode
        this._mapService.setEditingMarker(true);
      },
      error => {
        if (error.status === 403) {
          this._commonService.translateToaster("error", "NotAllowed");
        } else {
          console.error(error.error.message);
          this._commonService.translateToaster("error", "ErrorMessage");
          this.disabledAfterPost = false;
        }
      }
    );
  }

  ngOnDestroy() {
    this.fs.markerCoordinates = undefined;
    this.fs.geojsonCoordinates = undefined;
  }
}
