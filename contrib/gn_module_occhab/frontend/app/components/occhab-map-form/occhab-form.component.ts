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
import { filter } from "rxjs/operators";
import { L } from "leaflet";

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
  public datasets: Array<any>;
  public areaTypes: Array<any>;
  public currentStations: Array<any>;
  public currentLayers: Array<any>;
  public featuresAreas: any;
  public featuresStations: any;
  public stationsgeoJson: L.geoJSON;
  public areasgeoJson: L.geoJSON;


  constructor(
    public occHabForm: OcchabFormService,
    private _occHabDataService: OccHabDataService,
    public storeService: OcchabStoreService,
    private _route: ActivatedRoute,
    private _router: Router,
    private _commonService: CommonService,
    private _gnDataService: DataFormService,
    private _mapService: MapService
  ) { }

  ngOnInit() {
    // Récupère les datasets compatibles avec OccHab
    this._gnDataService.getDatasets({ 'module_code': 'OCCHAB' }).subscribe(data => {
      this.datasets = data.data;
    })
    this._gnDataService.getAreaTypes().subscribe(data => {
      this.areaTypes = data;
    })

    this.leafletDrawOptions;
    leafletDrawOption.draw.polyline = false;
    leafletDrawOption.draw.circle = false;
    leafletDrawOption.draw.rectangle = false;

    this.currentStations = [];
      this.currentLayers = [];

    this.occHabForm.stationForm = this.occHabForm.initStationForm();
    this.occHabForm.stationForm.controls.geom_4326.valueChanges.subscribe(d => {
      this.disabledForm = false;
    });
    this.storeService.defaultNomenclature$
      .pipe(filter(val => val !== null))
      .subscribe(val => {
        this.occHabForm.patchDefaultNomenclaureStation(val);
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

  fetchDatasetStations(datasetId, event) {
    this._occHabDataService.getStations(
      { 'id_dataset': datasetId }
    ).subscribe(geojsonStations => {
        if (event.checked) {
            // If checkbox checked, we add to related data to the currentStations list
            this.currentStations.push({IdDB:datasetId, Data:geojsonStations});
        } else {
            // If the checkbox is unchecked, we find the related data in the currentStations list and we remove it
            var indexDataset = this.currentStations.findIndex(dict=>dict.IdDB == datasetId);
            this.currentStations.splice(indexDataset, 1);
        }

        // We start a new featureCollection that will contain all the selected features
        var featureCollection = {
            type: 'FeatureCollection',
            features: []
        };
        // We add all the features contained in the currentStations list, in the featureCollection
        this.currentStations.forEach(function(feature) {
            featureCollection.features.push(feature.Data);
        });
        this.featuresStations = featureCollection;

        // We display the features on the map
        this.setDatasetsOnLayers();
    })
  }

  fetchTypesAreas(typeId, event) {
      this._gnDataService.getAreas([typeId], undefined, 10000, true).subscribe(geojsonAreas => {
          if (event.checked) {
              // If checkbox checked, we add to related data to the currentLayers list
              var layer = [];
              geojsonAreas.forEach(function (area) {
                  layer.push(area.geojson_4326);
              });
              this.currentLayers.push({IdDB:typeId, Data:layer});
          } else {
              // If the checkbox is unchecked, we find the related data in the currentLayers list and we remove it
              var indexArea = this.currentLayers.findIndex(dict=>dict.IdDB == typeId);
              this.currentLayers.splice(indexArea, 1);
          }

        // We start a new featureCollection that will contain all the selected features
        var featureCollection = {
            type: 'FeatureCollection',
            features: []
        };

        // We add all the features contained in the currentStations list, in the featureCollection
        this.currentLayers.forEach(function(feature) {
            console.log(feature);
            var color = '#'+(0x1000000+(Math.random())*0xffffff).toString(16).substr(1,6)
            feature.Data.forEach(function(layer) {
                featureCollection.features.push({"type": "Feature", "geometry": JSON.parse(layer),
                    properties: {
                        name: "Multipolygon",
                        style: {
                            color: color,
                            opacity: 0.4,
                            fillColor: color,
                            fillOpacity: 0.1,
                            smoothFactor: 0.1
                        }
                    }
                });
            });
        });

        this.featuresAreas = featureCollection;

        this.setAreasOnLayers();
      })
  }

  setAreasOnLayers() {
      if (this.areasgeoJson) {
          this._mapService.map.removeLayer(this.areasgeoJson);
      }

      this.areasgeoJson = this._mapService.L.geoJSON(this.featuresAreas, {
          pointToLayer: (feature, latlng) => {
              return this._mapService.L.circleMarker(latlng)
          },
          style: function(feature) {
              return feature.properties.style
          }
      });

      this.areasgeoJson.addTo(this._mapService.map);
  }

  setDatasetsOnLayers() {

    // const stationsLayerGroup = this._mapService.L.geoJSON(this.geojsonStations$.getValue());
    if (this.stationsgeoJson) {
      this._mapService.map.removeLayer(this.stationsgeoJson);
    }

    this.stationsgeoJson = this._mapService.L.geoJSON(this.featuresStations, {
      pointToLayer: (feature, latlng) => {
        return this._mapService.L.circleMarker(latlng)
      }
    });

    this.stationsgeoJson.addTo(this._mapService.map);
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
