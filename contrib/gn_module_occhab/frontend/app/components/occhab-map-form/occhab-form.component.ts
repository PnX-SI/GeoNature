import { Component, OnInit } from "@angular/core";
import { OcchabFormService } from "../../services/form-service";
import { OcchabStoreService } from "../../services/store.service";
import { DataFormService } from "@geonature_common/form/data-form.service";
import { OccHabDataService } from "../../services/data.service";
import { leafletDrawOption } from "@geonature_common/map/leaflet-draw.options";
import { MapService } from "@geonature_common/map/map.service";
import { ActivatedRoute, Router } from "@angular/router";
import { Subscription } from "rxjs/Subscription";
import { CommonService } from "@geonature_common/service/common.service";
import { AppConfig } from "@geonature_config/app.config";
import { ModuleConfig } from "../../module.config";
import { MapListService } from "@geonature_common/map-list/map-list.service";
import { filter } from "rxjs/operators";
import * as moment from "moment";

@Component({
  selector: "pnx-occhab-form",
  templateUrl: "occhab-form.component.html",
  styleUrls: ["./occhab-form.component.scss", "../responsive-map.scss"],
  providers: [OcchabFormService]
})
export class OccHabFormComponent implements OnInit {
  public leafletDrawOptions = leafletDrawOption;
  public filteredHab: any;
  private _sub: Subscription;
  public editionMode = false;
  public MAP_SMALL_HEIGHT = "50vh !important;";
  public MAP_FULL_HEIGHT = "87vh";
  public mapHeight = this.MAP_FULL_HEIGHT;
  public appConfig = AppConfig;
  public moduleConfig = ModuleConfig;
  public showHabForm = false;
  public showTabHab = false;
  public showDepth = false;
  public disabledForm = true;
  public firstFileLayerMessage = true;
  public currentGeoJsonFileLayer;
  public markerCoordinates;
  public currentEditingStation: any;
  // boolean tocheck if the station has at least one hab (control the validity of the form)
  public atLeastOneHab = false;

  constructor(
    public occHabForm: OcchabFormService,
    private _occHabDataService: OccHabDataService,
    public storeService: OcchabStoreService,
    private _route: ActivatedRoute,
    private _router: Router,
    private _commonService: CommonService,
    public mapListService: MapListService,

    private _gnDataService: DataFormService,
    private _mapService: MapService
    
  ) {}

  ngOnInit() {
    this.leafletDrawOptions;
    leafletDrawOption.draw.polyline = false;
    leafletDrawOption.draw.circle = false;
    leafletDrawOption.draw.rectangle = false;

    this.occHabForm.stationForm = this.occHabForm.initStationForm();
    this.occHabForm.stationForm.controls.geom_4326.valueChanges.subscribe(d => {
      this.disabledForm = false;
    });
    this.storeService.defaultNomenclature$
      .pipe(filter(val => val !== null))
      .subscribe(val => {
        this.occHabForm.patchDefaultNomenclaureStation(val);
      });

    this.mapListService.geojsonData = null;

    this.occHabForm.stationForm.controls.id_dataset.valueChanges.subscribe(v => {
      if(this.occHabForm.stationForm.get('id_dataset').value != null){
        this._occHabDataService.getStations({'id_dataset':this.occHabForm.stationForm.get('id_dataset').value}).subscribe(
        featuresCollection => {
            this.mapListService.geojsonData = featuresCollection;
          },
          // error callback
          e => {
            if (e.status == 500) {
              this._commonService.translateToaster("error", "ErrorMessage");
            }
          }
        );
      }
    });
  }

  ngAfterViewInit() {
    // get the id from the route
    this._sub = this._route.params.subscribe(params => {
      if (params["id_station"]) {
        this.editionMode = true;
        this.atLeastOneHab = true;
        this.showHabForm = false;
        this.showTabHab = true;
        this._occHabDataService
          .getOneStation(params["id_station"])
          .subscribe(station => {
            this.currentEditingStation = station;
            if (station.geometry.type == "Point") {
              // set the input for the marker component
              this.markerCoordinates = station.geometry.coordinates;
            } else {
              // set the input for leaflet draw component
              this.currentGeoJsonFileLayer = station.geometry;
            }
            this.occHabForm.patchStationForm(station);
          });
      }
    });
  }

  originStyle = {
    color: '#3388ff',
    fill: false,
    fillColor: '#f03',
    fillOpacity: 0.2,
    weight: 3
  };

  onEachFeature(feature, layer) {
    layer.setStyle(this.originStyle);
     // event from the map
     layer.on({
       contextmenu: () => {
         // open popup
         (layer as any).setStyle({ color: 'red', fill: true, fillOpacity: 0.2});
         const leafletPopup: HTMLElement = document.createElement("div");
         leafletPopup.style.maxHeight = "80vh";
         leafletPopup.style.overflowY = "auto";
     
         const divObservateurs = document.createElement("div");
         divObservateurs.innerHTML = "<b> Observateurs : </b> <br>";
         divObservateurs.innerHTML =
           divObservateurs.innerHTML +
           this.displayObservateursTooltip(feature.properties).join(", ");
     
         const divDate = document.createElement("div");
         divDate.innerHTML = "<b> Date : </b> <br>";
         divDate.innerHTML =
           divDate.innerHTML + this.displayDateTooltip(feature.properties);
     
         const divHab = document.createElement("div");
         divHab.innerHTML = "<b> Habitats : </b> <br> ";
     
         divHab.style.marginTop = "5px";
         let taxons = this.displayHabTooltip(feature.properties).join("<br>");
         divHab.innerHTML = divHab.innerHTML + taxons;
     
         leafletPopup.appendChild(divObservateurs);
         leafletPopup.appendChild(divDate);
         leafletPopup.appendChild(divHab);
 
        layer.bindPopup(leafletPopup).openPopup();
       }
     });
 
     layer.on(
       {
         mouseout: () => {
             layer.setStyle(this.originStyle);
             layer.closePopup();
             layer.unbindPopup();
         }
       });
 
       layer.on(
         {
           click: () => {
               layer.setStyle(this.originStyle);
               layer.closePopup();
               layer.unbindPopup();
           }
         });
   }
   displayDateTooltip(element): string {
    return element.date_min == element.date_max
      ? moment(element.date_min).format("DD-MM-YYYY")
      : `Du ${moment(element.date_min).format("DD-MM-YYYY")} au ${moment(
          element.date_max
        ).format("DD-MM-YYYY")}`;
  }

  displayHabTooltip(row): string[] {
    let tooltip = [];
    if (row.t_habitats === undefined) {
      tooltip.push("Aucun habitat");
    } else {
      for (let i = 0; i < row.t_habitats.length; i++) {
        let occ = row.t_habitats[i];
        tooltip.push(occ.nom_cite);
      }
    }
    return tooltip.sort();
  }

  displayObservateursTooltip(row): string[] {
    let tooltip = [];
    if (row.observers === undefined) {
      if (row.observers_txt !== null && row.observers_txt.trim() !== "") {
        tooltip.push(row.observers_txt.trim());
      } else {
        tooltip.push("Aucun observateurs");
      }
    } else {
      for (let i = 0; i < row.observers.length; i++) {
        let obs = row.observers[i];
        tooltip.push([obs.prenom_role, obs.nom_role].join(" "));
      }
    }
    return tooltip.sort();
  }

  formIsDisable() {
    if (this.disabledForm) {
      this._commonService.translateToaster(
        "warning",
        "Releve.FillGeometryFirst"
      );
    }
  }

  // display help toaster for filelayer
  infoMessageFileLayer() {
    if (this.firstFileLayerMessage) {
      this._commonService.translateToaster("info", "Map.FileLayerInfoMessage");
    }
    this.firstFileLayerMessage = false;
  }

  addNewHab() {
    this.occHabForm.addNewHab();
    this.showHabForm = true;
  }

  validateHabitat() {
    this.showHabForm = false;
    this.showTabHab = true;
    this.occHabForm.currentEditingHabForm = null;
    this.atLeastOneHab = true;
  }

  // toggle the hab form and call the editHab function of form service
  editHab(index) {
    this.occHabForm.editHab(index);
    this.showHabForm = true;
  }

  cancelHab() {
    this.showHabForm = false;
    this.occHabForm.cancelHab();
  }

  toggleDepth() {
    this.showDepth = !this.showDepth;
  }

  postStation() {
    const station = this.occHabForm.formatStationBeforePost();
    this._occHabDataService.postStation(station).subscribe(
      data => {
        this.occHabForm.resetAllForm();
        this._router.navigate(["occhab"]);
      },
      error => {
        if (error.status === 403) {
          this._commonService.translateToaster("error", "NotAllowed");
        } else {
          this._commonService.translateToaster("error", "ErrorMessage");
        }
      }
    );
  }

  formatter(item) {
    return item.search_name;
  }

  loadDatasetGeom(event) {
    console.log(event);
  }

  ngOnDestroy() {
    this._sub.unsubscribe();
  }
}
