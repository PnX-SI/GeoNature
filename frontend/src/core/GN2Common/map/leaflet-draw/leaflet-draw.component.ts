import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';
import { Map, FeatureGroup } from 'leaflet';
import { MapService } from '../map.service';
import { MapUtils } from '../map.utils';
import { mapOptions } from '../map.options';

import 'leaflet-draw';
import * as L from 'leaflet';

@Component({
  selector: 'pnx-leaflet-draw',
  templateUrl: 'leaflet-draw.component.html'
})

export class LeafletDrawComponent implements OnInit {
  public map: Map;
  private _currentDraw:any;
  private _drawFeatureGroup: FeatureGroup;
  private _Le: any;
  @Input() options: any;
  @Output() layerDrawed = new EventEmitter<any>();

  constructor(public mapservice: MapService, private _maputils: MapUtils) { }

  ngOnInit() {
    this.map = this.mapservice.map;
    this._Le = L as any;
    this.enableLeafletDraw();
   }

   enableLeafletDraw() {
    mapOptions.leafletDraw.options.edit['featureGroup'] = this.mapservice.releveFeatureGroup;
    const drawControl =  new this._Le.Control.Draw(mapOptions.leafletDraw.options);
    this.map.addControl(drawControl);

    this.map.on(this._Le.Draw.Event.DRAWSTART, (e) => {
      // remove the current draw
      if (this._currentDraw !== null) {
        this._maputils.removeAllLayers(this.map, this.mapservice.releveFeatureGroup);
      }
      // remove the current marker
      const markerLegend = document.getElementById('markerLegend');
      if(markerLegend){
        markerLegend.style.backgroundColor = 'white';
      }
      this.mapservice.editingMarker = false;
      this.map.off('click');
      if (this.mapservice.marker) {
        this.map.removeLayer(this.mapservice.marker);
      }
    });

    // on draw layer created
    this.map.on(this._Le.Draw.Event.CREATED, (e) => {
      if (this.map.getZoom() < 5) {
        // this.translate.get('Map.ZoomWarning', {value: 'Map.ZoomWarning'})
        //   .subscribe(res =>
        //     this.toastrService.warning(res, '', this.toastrConfig)
        //   );
      }else {
        this._currentDraw = (e as any).layer;
        const layerType = (e as any).layerType;
        const latlngTab = this._currentDraw._latlngs;
        this.mapservice.releveFeatureGroup.addLayer(this._currentDraw);
        let geojson = this.mapservice.releveFeatureGroup.toGeoJSON();
        geojson = (geojson as any).features[0];
        // output
        this.layerDrawed.emit(geojson);
      }

    });
  }
}