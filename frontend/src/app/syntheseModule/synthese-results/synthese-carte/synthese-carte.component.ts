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

  coordsToLatLng(coordinates) {
    return new L.LatLng(coordinates[1], coordinates[0]);
  }

  setStyleEventAndAdd(layer, id) {
    this.setStyle(layer);
    this.eventOnEachFeature(id, layer);
    this.cluserOrSimpleFeatureGroup.addLayer(layer);
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

      change.inputSyntheseData.currentValue.features.forEach(geojson => {
        // we don't create a generic function for setStyle and event on each layer to avoid
        // a if on possible milion of point (with multipoint we must set the event on each point)
        if (geojson.type == 'Point' || geojson.type == 'MultiPoint') {
          if (geojson.type == 'Point') {
            geojson.coordinates = [geojson.coordinates];
          }
          for (let i = 0; i < geojson.coordinates.length; i++) {
            const latLng = L.GeoJSON.coordsToLatLng(geojson.coordinates[i]);
            this.setStyleEventAndAdd(L.circleMarker(latLng), geojson.properties.id);
          }
        } else if (geojson.type == 'Polygon' || geojson.type == 'MultiPolygon') {
          const latLng = L.GeoJSON.coordsToLatLngs(
            geojson.coordinates,
            geojson.type === 'Polygon' ? 1 : 2
          );
          this.setStyleEventAndAdd(new L.Polygon(latLng), geojson.properties.id);
        } else if (geojson.type == 'LineString' || geojson.type == 'MultiLineString') {
          const latLng = L.GeoJSON.coordsToLatLngs(
            geojson.coordinates,
            geojson.type === 'LineString' ? 0 : 1
          );
          this.setStyleEventAndAdd(new L.Polyline(latLng), geojson.properties.id);
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
