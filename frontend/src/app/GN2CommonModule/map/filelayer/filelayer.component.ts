import {
  Component,
  OnInit,
  Output,
  Input,
  EventEmitter,
  AfterViewInit,
  OnChanges
} from '@angular/core';
import { MapService } from '../map.service';
import { Map } from 'leaflet';
import * as L from 'leaflet';
import * as ToGeojson from 'togeojson';
import * as FileLayer from 'leaflet-filelayer';
import { CommonService } from '@geonature_common/service/common.service';

@Component({
  selector: 'pnx-leaflet-filelayer',
  templateUrl: './filelayer.component.html'
})
export class LeafletFileLayerComponent implements OnInit, AfterViewInit, OnChanges {
  public map: Map;
  public Le: any;
  public previousLayer: any;
  public fileLayerControl: L.Control;
  // input to detect a new layer on the map
  // when this input change -> delete the layer
  @Input() removeLayer: any;
  @Output() onLoad = new EventEmitter<any>();
  constructor(public mapService: MapService, private _commonService: CommonService) {}

  ngOnInit() {}

  ngAfterViewInit() {
    this.mapService.initializefileLayerFeatureGroup();
    this.map = this.mapService.getMap();

    FileLayer(null, L, ToGeojson);
    (L.Control as any).FileLayerLoad.LABEL =
      '<img class="icon" width="15" src="assets/images/folder.svg" alt="file icon"/>';
    this.fileLayerControl = (L.Control as any)
      .fileLayerLoad({
        layer: (L as any).geoJson,
        // Add to map after loading (default: true) ?
        addToMap: false,
        // File size limit in kb (default: 1024) ?
        fileSizeLimit: 1024,
        // Restrict accepted file formats (default: .geojson, .json, .kml, and .gpx) ?
        formats: ['.gpx', '.geojson', '.kml']
      })
      .addTo(this.map);

    // event on load success
    (this.fileLayerControl as any).loader.on('data:loaded', event => {
      // remove layer from leaflet draw
      this.mapService.removeAllLayers(this.mapService.map, this.mapService.leafletDrawFeatureGroup);
      // remove the previous layer loaded via file layer
      this.mapService.removeAllLayers(this.mapService.map, this.mapService.fileLayerFeatureGroup);
      let currentFeature;

      const geojsonArray = [];
      // loop on layers to set them on the map via the fileLayerFeatureGroup
      // tslint:disable-next-line:forin
      for (let _layer in event.layer._layers) {
        // emit the geometry as an output
        currentFeature = event.layer._layers[_layer]['feature'];
        geojsonArray.push(currentFeature);

        // create a geojson with the name on over
        const newLayer = L.geoJSON(currentFeature, {
          pointToLayer: (feature, latlng) => {
            return L.circleMarker(latlng);
          },
          onEachFeature: (feature, layer) => {
            let propertiesContent = '';
            // loop on properties dict to build the popup
            // tslint:disable-next-line:forin
            for (let prop in currentFeature.properties) {
              propertiesContent +=
                '<b>' + prop + '</b> : ' + currentFeature.properties[prop] + ' ' + '<br>';
            }
            if (propertiesContent.length > 0) {
              layer.bindPopup(propertiesContent);
            }
            layer.on('mouseover', e => {
              layer.openPopup();
            });
            layer.on('mouseout', e => {
              layer.closePopup();
            });
          },
          style: this.mapService.searchStyle
        });
        // add the layers to the feature groupe
        this.mapService.fileLayerFeatureGroup.addLayer(newLayer);

        this.onLoad.emit(geojsonArray);
      }
      // remove the previous layer of the map
      if (this.previousLayer) {
        this.map.removeLayer(this.previousLayer);
      }
      this.previousLayer = event.layer;
    });

    // event on load fail

    (this.fileLayerControl as any).loader.on('data:error', error => {
      this._commonService.translateToaster('error', 'ErrorMessage');
      console.error(error);
    });
  }

  ngOnChanges(changes) {
    if (changes && changes.removeLayer && changes.removeLayer.currentValue) {
      if (this.previousLayer) {
        // when this input change -> delete the layer because an other layer has been loaded
        this.map.removeLayer(this.previousLayer);
      }
    }
  }
}
