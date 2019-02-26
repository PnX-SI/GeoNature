import { Component, OnInit, Input, AfterViewInit, OnChanges } from '@angular/core';
import { GeoJSON } from 'leaflet';
import { MapListService } from '@geonature_common/map-list/map-list.service';
import { MapService } from '@geonature_common/map/map.service';
import { leafletDrawOption } from '@geonature_common/map/leaflet-draw.options';
import { SyntheseFormService } from '../../services/form.service';
import { CommonService } from '@geonature_common/service/common.service';
import { AppConfig } from '@geonature_config/app.config';
import * as L from 'leaflet';

@Component({
  selector: 'pnx-synthese-carte',
  templateUrl: 'synthese-carte.component.html',
  styleUrls: ['synthese-carte.component.scss'],
  providers: []
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

  originStyle = {
    color: '#3388ff',
    fill: false,
    weight: 3
  };

  selectedStyle = {
    color: '#ff0000',
    weight: 3,
    fill: true
  };

  @Input() inputSyntheseData: GeoJSON;
  constructor(
    public mapListService: MapListService,
    private _ms: MapService,
    public formService: SyntheseFormService,
    private _commonService: CommonService
  ) {}

  ngOnInit() {
    this.leafletDrawOptions.draw.rectangle = true;
    this.leafletDrawOptions.draw.circle = true;
    this.leafletDrawOptions.draw.polyline = false;
    this.leafletDrawOptions.edit.remove = true;
  }

  ngAfterViewInit() {
    // event from the list
    // On table click, change style layer and zoom
    this.mapListService.onTableClick$.subscribe(id => {
      const selectedLayer = this.mapListService.layerDict[id];
      //selectedLayer.bringToFront();
      this.toggleStyle(selectedLayer);
      this.mapListService.zoomOnSelectedLayer(this._ms.map, selectedLayer);
    });

    // add the featureGroup to the map
    this.cluserOrSimpleFeatureGroup.addTo(this._ms.map);
  }

  // redefine toggle style from mapListSerice because we don't use geojson component here for perf reasons
  toggleStyle(selectedLayer) {
    // togle the style of selected layer
    if (this.mapListService.selectedLayer !== undefined) {
      this.mapListService.selectedLayer.setStyle(this.originStyle);
    }
    this.mapListService.selectedLayer = selectedLayer;
    this.mapListService.selectedLayer.setStyle(this.selectedStyle);
  }

  eventOnEachFeature(id: number, layer): void {
    // event from the map
    this.mapListService.layerDict[id] = layer;
    layer.on({
      click: e => {
        // toggle style
        this.toggleStyle(layer);
        this.mapListService.mapSelected.next(id);
      }
    });
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

  setStyle(layer) {
    layer.setStyle({
      color: '#3388ff',
      weight: 3,
      fill: false
    });
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
        ? (L as any).markerClusterGroup()
        : new L.FeatureGroup();

      change.inputSyntheseData.currentValue.features.forEach(element => {
        if (element.type === 'Point') {
          const latLng = L.latLng(element.coordinates[1], element.coordinates[0]);
          const marker = L.circleMarker(latLng);
          this.setStyle(marker);
          this.eventOnEachFeature(element.properties.id, marker);
          this.cluserOrSimpleFeatureGroup.addLayer(marker);
        } else if (element.type === 'Polygon') {
          const myLatLong = element.coordinates[0].map(point => {
            return L.latLng(point[1], point[0]);
          });
          const layer = L.polygon(myLatLong);
          this.setStyle(layer);
          this.eventOnEachFeature(element.properties.id, layer);
          this.cluserOrSimpleFeatureGroup.addLayer(layer);
        } else {
          // its a LineStrinbg
          const myLatLong = element.coordinates.map(point => {
            return L.latLng(point[1], point[0]);
          });
          const layer = L.polyline(myLatLong);
          this.setStyle(layer);
          this.eventOnEachFeature(element.properties.id, layer);
          this.cluserOrSimpleFeatureGroup.addLayer(layer);
        }
      });
      this._ms.map.addLayer(this.cluserOrSimpleFeatureGroup);
      // zoom on extend after first search
      if (change.inputSyntheseData.previousValue !== undefined) {
        try {
          // try to fit bound on layer. catch error if no layer in feature group
          this._ms.map.fitBounds(this.cluserOrSimpleFeatureGroup.getBounds());
        } catch (error) {
          console.log('no layer in feature group');
        }
      }
    }
  }
}
