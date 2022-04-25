import { Component, OnInit, Input, AfterViewInit, OnChanges } from '@angular/core';
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

  originStyle = {
    color: '#E0C0F0',
    opacity: 0.8,
    weight: 4,
    fillColor: '#9E48C7',
    fillOpacity: 0.5
  };

  selectedStyle = {
    color: '#ff0000',
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
    this.mapListService.onTableClick$.subscribe((id) => {
      const selectedLayer = this.mapListService.layerDict[id];
      //selectedLayer.bringToFront();
      this.toggleStyle(selectedLayer);
      this.mapListService.zoomOnSelectedLayer(this._ms.map, selectedLayer);
      selectedLayer.bringToFront();
    });

    // add the featureGroup to the map
    this.cluserOrSimpleFeatureGroup.addTo(this._ms.map);
  }

  // redefine toggle style from mapListSerice because we don't use geojson component here for perf reasons
  private toggleStyle(selectedLayer) {
    // togle the style of selected layer
    if (this.mapListService.selectedLayer !== undefined) {
      this.mapListService.selectedLayer.setStyle(this.originStyle);
    }
    this.mapListService.selectedLayer = selectedLayer;
    this.mapListService.selectedLayer.setStyle(this.selectedStyle);
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
            let markerIds = geojson.properties.id;
            let marker = L.circleMarker(latLng).bindTooltip(`${countId}`, {
              permanent: true,
              direction: 'center',
              className: 'number-obs',
            });
            this.setStyleCircleMarker(marker, countId);
            this.eventOnEachFeature(markerIds, marker);
            this.cluserOrSimpleFeatureGroup.addLayer(marker);
          }
        } else if (geojson.geometry.type == 'Polygon' || geojson.geometry.type == 'MultiPolygon') {
          const latLng = L.GeoJSON.coordsToLatLngs(
            geojson.geometry.coordinates,
            geojson.geometry.type === 'Polygon' ? 1 : 2
          );
          this.setStyleEventAndAdd(new L.Polygon(latLng), geojson.properties.id);
        } else if (
          geojson.geometry.type == 'LineString' ||
          geojson.geometry.type == 'MultiLineString'
        ) {
          const latLng = L.GeoJSON.coordsToLatLngs(
            geojson.geometry.coordinates,
            geojson.geometry.type === 'LineString' ? 0 : 1
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


  private setStyleCircleMarker(layer, ids) {
    layer.setStyle({
      color: '#E0C0F0',
      opacity: 0.8,
      weight: 4,
      radius: 10+ids,
      fillColor: '#9E48C7',
      fillOpacity: 0.5
    });
  }


  private setStyleEventAndAdd(layer, ids) {
    this.setStyle(layer);
    this.eventOnEachFeature(ids, layer);
    this.cluserOrSimpleFeatureGroup.addLayer(layer);
  }

  private setStyle(layer) {
    layer.setStyle({
      color: '#3388ff',
      weight: 3,
      fill: false,
    });
  }

  private eventOnEachFeature(ids, layer): void {
    // event from the map
    for (let id of ids) {
      this.mapListService.layerDict[id] = layer;
    }
    layer.on({
      click: (e) => {
        // toggle style
        this.toggleStyle(layer);
        this.mapListService.mapSelected.next(ids);
      },
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

  // coordsToLatLng(coordinates) {
  //   return new L.LatLng(coordinates[1], coordinates[0]);
  // }
}
