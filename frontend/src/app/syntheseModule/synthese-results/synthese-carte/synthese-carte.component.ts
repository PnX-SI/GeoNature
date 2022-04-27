import { Component, OnInit, Input, AfterViewInit, EventEmitter, OnChanges, Output } from '@angular/core';
import { GeoJSON } from 'leaflet';
import { MapListService } from '@geonature_common/map-list/map-list.service';
import { MapService } from '@geonature_common/map/map.service';
import { leafletDrawOption } from '@geonature_common/map/leaflet-draw.options';
import { SyntheseFormService } from '@geonature_common/form/synthese-form/synthese-form.service';
import { CommonService } from '@geonature_common/service/common.service';
import { AppConfig } from '@geonature_config/app.config';
import * as L from 'leaflet';

@Component({
  selector: 'pnx-synthese-carte',
  templateUrl: 'synthese-carte.component.html',
  styleUrls: ['synthese-carte.component.scss'],
  providers: [],
})
export class SyntheseCarteComponent implements OnInit, AfterViewInit, OnChanges {

  public leafletDrawOptions = leafletDrawOption;
  public currentLeafletDrawCoord: any;
  public firstFileLayerMessage = true;
  public SYNTHESE_CONFIG = AppConfig.SYNTHESE;
  // set a new featureGroup - cluster or not depending of the synthese config
  public cluserOrSimpleFeatureGroup = AppConfig.SYNTHESE.ENABLE_LEAFLET_CLUSTER
    ? (L as any).markerClusterGroup()
    : new L.FeatureGroup();

  private meshesEnable = false;
  private meshesLegend;
  private enableFitBounds = true;

  private originDefaultStyle = {
    color: '#3388ff',
    weight: 3,
    fill: false,
  };
  private selectedDefaultStyle = {
    color: '#ff0000',
  };
  private originMeshesStyle = {
    color: '#FFFFFF',
    weight: 0.4,
    fillOpacity: 0.8,
  };
  private selectedMeshesStyle = {
    color: '#ff0000',
    weight: 3,
  };

  @Input() inputSyntheseData: GeoJSON;
  @Output() onMeshesToggle = new EventEmitter<any>()

  constructor(
    public mapListService: MapListService,
    private _ms: MapService,
    public formService: SyntheseFormService,
    private _commonService: CommonService,
  ) { }

  ngOnInit() {
    this.leafletDrawOptions.draw.rectangle = true;
    this.leafletDrawOptions.draw.circle = true;
    this.leafletDrawOptions.draw.polyline = false;
    this.leafletDrawOptions.edit.remove = true;
  }

  ngAfterViewInit() {
    // event from the list
    // On table click, change style layer and zoom
    this.mapListService.onTableClick$.subscribe((id) => {
      const selectedLayer = this.mapListService.layerDict[id];
      //selectedLayer.bringToFront();
      this.toggleStyle(selectedLayer);
      this.mapListService.zoomOnSelectedLayer(this._ms.map, selectedLayer);
      selectedLayer.bringToFront();
    });

    // add the featureGroup to the map
    this.cluserOrSimpleFeatureGroup.addTo(this._ms.map);

    // Handle meshes button and legend
    this.addMeshesButton();
  }

  addMeshesButton() {
    const LayerControl = L.Control.extend({
      options: {
        position: 'topright',
      },
      onAdd: (map) => {
        let switchBtnContainer = L.DomUtil.create(
          'div',
          'leaflet-bar custom-control custom-switch leaflet-control-custom synthese-map-meshes'
        );

        let switchBtn = L.DomUtil.create(
          'input',
          'custom-control-input',
          switchBtnContainer
        );
        switchBtn.id = 'toggle-meshes-btn';
        switchBtn.type = 'checkbox';
        switchBtn.onclick = () => {
          this.meshesEnable = switchBtn.checked
          this.formService.searchForm.patchValue({
            "with_meshes": switchBtn.checked
          });
          this.formService.searchForm.markAsDirty();
          this.onMeshesToggle.emit(this.formService.formatParams());

          // Show meshes legend if meshes toggle button is enable
          if (this.meshesEnable) {
            this.addMeshesLegend();
          } else {
            this.removeMeshesLegend();
            this.enableFitBounds = false;
          }
        };

        let labelSwitchBtn = L.DomUtil.create(
          'label',
          'custom-control-label',
          switchBtnContainer
        );
        labelSwitchBtn.setAttribute('for', 'toggle-meshes-btn');
        labelSwitchBtn.innerText = 'Mailles';

        return switchBtnContainer;
      },
    });

    const map = this._ms.getMap()
    map.addControl(new LayerControl);
  }

  private addMeshesLegend() {
    this.meshesLegend = new (L.Control.extend({
      options: { position: 'bottomright' }
    }));

    const vm = this;
    this.meshesLegend.onAdd = function (map) {
      let div = L.DomUtil.create("div", "info legend");
      let grades = [0, 1, 2, 5, 10, 20, 50, 100];
      let labels = ["<strong> Nombre <br> d'observations </strong> <br>"];

      // loop through our density intervals and generate a label with a colored square for each interval
      for (var i = 0; i < grades.length; i++) {
        labels.push(
          '<i style="background:' +
          vm.getColor(grades[i] + 1) +
          '"></i> ' +
          grades[i] +
          (grades[i + 1] ? "&ndash;" + grades[i + 1] + "<br>" : "+")
        );
      }
      div.innerHTML = labels.join("<br>");

      return div;
    };

    const map = this._ms.getMap();
    this.meshesLegend.addTo(map);
  }

  private removeMeshesLegend() {
    const map = this._ms.getMap();
    this.meshesLegend.remove(map);
  }

  ngOnChanges(change) {
    // on change delete the previous layer and load the new ones from the geojson data send by the API
    // here we don't use geojson component for performance reasons
    if (this._ms.map) {
      // remove the whole featureGroup to avoid iterate over all its layer
      this._ms.map.removeLayer(this.cluserOrSimpleFeatureGroup);
    }
    if (change && change.inputSyntheseData.currentValue) {
      // regenerate the featuregroup
      this.cluserOrSimpleFeatureGroup = AppConfig.SYNTHESE.ENABLE_LEAFLET_CLUSTER
        ? (L as any).markerClusterGroup({
          iconCreateFunction: (cluster) => {
            const obsChildCount = cluster.getAllChildMarkers()
              .map(marker => marker.countObs)
              .reduce((previous, next) => previous + next);
            const clusterSize = (obsChildCount > 100)
              ? 'large'
              : (obsChildCount > 10)
                ? 'medium'
                : 'small';
            return L.divIcon({
              html: `<div><span>${obsChildCount}</span></div>`,
              className: `marker-cluster marker-cluster-${clusterSize}`,
              iconSize: L.point(40, 40)
            });
          }
        })
        : new L.FeatureGroup();

      change.inputSyntheseData.currentValue.features.forEach((geojson) => {
        let countObs = geojson.properties.observations.id.length
        // we don't create a generic function for setStyle and event on each layer to avoid
        // a if on possible milion of point (with multipoint we must set the event on each point)
        if (geojson.geometry.type == 'Point' || geojson.geometry.type == 'MultiPoint') {
          if (geojson.geometry.type == 'Point') {
            geojson.geometry.coordinates = [geojson.geometry.coordinates];
          }
          for (let i = 0; i < geojson.geometry.coordinates.length; i++) {
            const latLng = L.GeoJSON.coordsToLatLng(geojson.geometry.coordinates[i]);
            const circleMarker = L.circleMarker(latLng);
            circleMarker.bindTooltip(`${countObs}`, {
              permanent: true,
              direction: 'center',
              className: 'number-obs',
            });
            circleMarker['countObs'] = countObs;
            this.setStyleEventAndAdd(circleMarker, geojson.properties.observations.id);
          }
        } else if (geojson.geometry.type == 'Polygon' || geojson.geometry.type == 'MultiPolygon') {
          const latLng = L.GeoJSON.coordsToLatLngs(
            geojson.geometry.coordinates,
            geojson.geometry.type === 'Polygon' ? 1 : 2
          );
          if (this.meshesEnable) {
            this.setMeshesStyle(new L.Polygon(latLng), geojson.properties.observations.id);
          }
          else {
            this.setStyleEventAndAdd(new L.Polygon(latLng), geojson.properties.observations.id);
          }
        } else if (geojson.geometry.type == 'LineString' || geojson.geometry.type == 'MultiLineString') {
          const latLng = L.GeoJSON.coordsToLatLngs(
            geojson.geometry.coordinates,
            geojson.geometry.type === 'LineString' ? 0 : 1
          );
          this.setStyleEventAndAdd(new L.Polyline(latLng), geojson.properties.observations.id);
        }
      });
      this._ms.map.addLayer(this.cluserOrSimpleFeatureGroup);
      // zoom on extend after first search
      if (change.inputSyntheseData.previousValue !== undefined) {
        try {
          // try to fit bound on layer. catch error if no layer in feature group
          if (this.enableFitBounds) {
            this._ms.map.fitBounds(this.cluserOrSimpleFeatureGroup.getBounds());
          } else {
            this.enableFitBounds = true;
          }
        } catch (error) {
          console.log('no layer in feature group');
        }
      }
    }
  }

  private setMeshesStyle(layer, ids) {
    this.originMeshesStyle['fillColor'] = this.getColor(ids.length);
    layer.setStyle(this.originMeshesStyle);
    this.eventOnEachFeature(ids, layer);
    this.cluserOrSimpleFeatureGroup.addLayer(layer);
  }

  private getColor(obsNbr) {
    return obsNbr > 100
      ? "#800026"
      : obsNbr > 50
        ? "#BD0026"
        : obsNbr > 20
          ? "#E31A1C"
          : obsNbr > 10
            ? "#FC4E2A"
            : obsNbr > 5
              ? "#FD8D3C"
              : obsNbr > 2
                ? "#FEB24C"
                : obsNbr > 1
                  ? "#FED976"
                  : "#FFEDA0";
  }

  private setStyleEventAndAdd(layer, ids) {
    this.setDefaultStyle(layer);
    this.eventOnEachFeature(ids, layer);
    this.cluserOrSimpleFeatureGroup.addLayer(layer);
  }

  private setDefaultStyle(layer) {
    layer.setStyle(this.originDefaultStyle);
  }

  private eventOnEachFeature(ids, layer): void {
    // event from the map
    for (let id of ids) {
      this.mapListService.layerDict[id] = layer;
    }
    layer.on({
      click: (e) => {
        this.toggleStyle(layer);
        this.mapListService.mapSelected.next(ids);
        if (this.meshesEnable) {
          this.bindMeshesPopup(layer, ids);
        }
      },
    });
  }

  // Redefine toggle style from mapListSerice because we don't use geojson component here for perf reasons
  private toggleStyle(selectedLayer) {
    // Reset style of previous selected layer
    if (this.mapListService.selectedLayer !== undefined) {
      let originStyle = (this.meshesEnable) ? this.originMeshesStyle : this.originDefaultStyle;
      this.mapListService.selectedLayer.setStyle(originStyle);
    }

    // Apply new selected layer
    this.mapListService.selectedLayer = selectedLayer;

    // Set selected style on new selected layer
    let selectedStyle = (this.meshesEnable) ? this.selectedMeshesStyle : this.selectedDefaultStyle;
    this.mapListService.selectedLayer.setStyle(selectedStyle);
  }

  private bindMeshesPopup(layer, ids) {
    let popupContent = `<b>${ids.length} observation(s)</b>`;
    layer.bindPopup(popupContent).openPopup();
  }

  bindGeojsonForm(geojson) {
    this.formService.searchForm.controls.radius.setValue(geojson.properties['radius']);
    this.formService.searchForm.controls.geoIntersection.setValue(geojson);
    // set the current coord of the geojson to remove layer from filelayer component via the input removeLayer
    this.currentLeafletDrawCoord = geojson;
  }

  onFileLayerLoaded(geojson) {
    this.formService.searchForm.controls.geoIntersection.setValue(geojson);

    if (this.firstFileLayerMessage) {
      this._commonService.translateToaster('success', 'Map.FileLayerInfoSynthese');
    }
    this.firstFileLayerMessage = false;
  }

  deleteControlValue() {
    this.formService.searchForm.controls.geoIntersection.reset();
    this.formService.searchForm.controls.radius.reset();
  }
}
