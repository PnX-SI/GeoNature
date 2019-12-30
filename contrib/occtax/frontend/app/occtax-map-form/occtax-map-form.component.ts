import {
  Component,
  OnInit,
  Output,
  OnDestroy,
  ViewChild,
  AfterViewInit,
  EventEmitter
} from "@angular/core";
import { MapService } from "@geonature_common/map/map.service";
import { leafletDrawOption } from "@geonature_common/map/leaflet-draw.options";
import { ActivatedRoute, Router } from "@angular/router";
import { Subscription } from "rxjs/Subscription";
import { ModuleConfig } from "../module.config";
import { OcctaxFormService } from "./form/occtax-form.service";
import { CommonService } from "@geonature_common/service/common.service";
import { OcctaxDataService } from "../services/occtax-data.service";
import { DataFormService } from "@geonature_common/form/data-form.service";
import { MarkerComponent } from "@geonature_common/map/marker/marker.component";
import { AuthService } from "@geonature/components/auth/auth.service";

@Component({
  selector: "pnx-occtax-map-form",
  templateUrl: "./occtax-map-form.component.html",
  styleUrls: ["./occtax-map-form.component.scss"],
  // important to provide a new instance of OcctaxFormService to réinitialize it
  providers: [MapService, OcctaxFormService]
})
export class OcctaxMapFormComponent
  implements OnInit, OnDestroy, AfterViewInit {
  public leafletDrawOptions: any;
  private _sub: Subscription;
  public id: number;
  @ViewChild(MarkerComponent)
  public markerComponent: MarkerComponent;
  public firstFileLayerMessage = true;

  public occtaxConfig = ModuleConfig;
  constructor(
    private _ms: MapService,
    private _route: ActivatedRoute,
    private _router: Router,
    private _commonService: CommonService,
    public fs: OcctaxFormService,
    private occtaxService: OcctaxDataService,
    private _dfs: DataFormService,
    private _authService: AuthService
  ) {}

  ngOnInit() {
    // overight the leaflet draw object to set options
    // examples: enable circle =>  leafletDrawOption.draw.circle = true;
    leafletDrawOption.draw.circle = false;
    leafletDrawOption.draw.rectangle = false;
    leafletDrawOption.draw.marker = false;
    leafletDrawOption.draw.polyline = true;
    leafletDrawOption.edit.remove = false;
    this.leafletDrawOptions = leafletDrawOption;

    // refresh the forms
    this.fs.releveForm = this.fs.initReleveForm();
    this.fs.occurrenceForm = this.fs.initOccurenceForm();
    this.fs.countingForm = this.fs.initCountingArray();

    // patch default values in ajax
    this.fs.patchAllDefaultNomenclature();
  }

  ngAfterViewInit() {
    // get the id from the route
    this._sub = this._route.params.subscribe(params => {
      this.id = +params["id"];

      // if its edition mode
      if (!isNaN(this.id)) {
        // set showOccurrence to false;
        this.fs.showOccurrence = false;
        this.fs.editionMode$.next(true);
        this.fs.editionMode = true;
        // load one releve
        this.occtaxService.getOneReleve(this.id).subscribe(
          data => {
            // save the current releve
            this.fs.currentReleve = data;
            //test if observers exist.
            //Case when some releves were create with 'observers_txt : true' and others with 'observers_txt : false'
            //if this case comes up with 'observers_txt : false', the form is load with an empty 'observers' input
            //indeed, the application can not make the correspondence between an observer_txt and an id_role
            if (data.releve.properties.observers) {
              data.releve.properties.observers = data.releve.properties.observers.map(
                obs => {
                  obs["nom_complet"] = obs.nom_role + " " + obs.prenom_role;
                  return obs;
                }
              );
            }

            // pre fill the form

            data.releve.properties.hour_min =
              data.releve.properties.hour_min === "None"
                ? null
                : data.releve.properties.hour_min;

            data.releve.properties.hour_max =
              data.releve.properties.hour_max === "None"
                ? null
                : data.releve.properties.hour_max;
            this.fs.currentHourMax = data.releve.properties.hour_max;

            data.releve.properties.date_min = this.fs.formatDate(
              data.releve.properties.date_min
            );
            data.releve.properties.date_max = this.fs.formatDate(
              data.releve.properties.date_max
            );

            this.fs.releveForm.patchValue({
              properties: data.releve.properties
            });

            data.releve.properties.t_occurrences_occtax.forEach(occ => {
              this.fs.taxonsList.push(occ.taxref);
            });

            // set the occurrence
            this.fs.indexOccurrence =
              data.releve.properties.t_occurrences_occtax.length;
            // push the geometry in releveForm
            this.fs.releveForm.patchValue({ geometry: data.releve.geometry });
            // load the geometry in the map

            //this._ms.loadGeometryReleve(data.releve, true);
            if (data.releve.geometry.type == "Point") {
              // set the input for the marker component
              this.fs.markerCoordinates = data.releve.geometry.coordinates;
            } else {
              // set the input for leafletdraw component
              this.fs.geojsonCoordinates = data.releve.geometry;
            }

            this.fs.releveForm.patchValue({ geometry: data.releve.geometry });
          },
          error => {
            if (error.status === 403) {
              this._commonService.translateToaster("error", "NotAllowed");
            } else if (error.status === 404) {
              this._commonService.translateToaster(
                "error",
                "Releve.DoesNotExist"
              );
            }

            this._router.navigate(["/occtax"]);
          }
        ); // end subscribe
      } else {
        this.fs.editionMode$.next(false);
        // set digitiser as default observers only if occtaxconfig set observers_txt parameter to false
        if (!this.occtaxConfig.observers_txt) {
          const currentUser = this._authService.getCurrentUser();
          this.fs.releveForm.patchValue({
            properties: {
              observers: [currentUser],
              id_digitiser: currentUser.id_role
            }
          });
        }
      }
    });
  }

  // display help toaster for filelayer
  infoMessageFileLayer() {
    if (this.firstFileLayerMessage) {
      this._commonService.translateToaster("info", "Map.FileLayerInfoMessage");
    }
    this.firstFileLayerMessage = false;
  }

  sendGeoInfo(geojson) {
    this._ms.setGeojsonCoord(geojson);
  }

  ngOnDestroy() {
    this._sub.unsubscribe();
  }
}
