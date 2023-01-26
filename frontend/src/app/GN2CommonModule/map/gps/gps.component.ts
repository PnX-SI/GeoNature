import { Component, OnInit, ViewChild } from '@angular/core';
import { MarkerComponent } from '../marker/marker.component';
import { MapService } from '../map.service';
import { MapListService } from '../../map-list/map-list.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { CommonService } from '../../service/common.service';
import * as L from 'leaflet';
import { ConfigService } from '@geonature/services/config.service';

/**
 * Affiche une modale permettant de renseigner les coordonnées d'une observation, puis affiche un marker à la position renseignée.
 *
 * Ce composant hérite du composant MarkerComponent: il dispose donc des mêmes inputs et outputs.
 */
@Component({
  selector: 'pnx-gps',
  templateUrl: 'gps.component.html',
})
export class GPSComponent extends MarkerComponent implements OnInit {
  @ViewChild('modalContent', { static: false }) public modalContent: any;
  constructor(
    public mapService: MapService,
    public modalService: NgbModal,
    public commonService: CommonService,
    private _mapListServive: MapListService,
    public config: ConfigService
  ) {
    super(mapService, commonService, config);
  }

  ngOnInit() {
    this.map = this.mapservice.map;
    this.enableGps();
  }
  enableGps() {
    const GPSLegend = this.mapService.addCustomLegend('topleft', 'GPSLegend');
    this.map.addControl(new GPSLegend());
    const gpsElement: HTMLElement = document.getElementById('GPSLegend');
    L.DomEvent.disableClickPropagation(gpsElement);
    gpsElement.innerHTML = '<span> <b> GPS </span> <b>';
    gpsElement.style.paddingLeft = '3px';
    gpsElement.onclick = () => {
      this.modalService.open(this.modalContent);
    };
  }

  setMarkerFromGps(x, y) {
    super.generateMarkerAndEvent(x, y);
    // remove others layers
    this.mapService.removeAllLayers(this.mapService.map, this.mapService.leafletDrawFeatureGroup);
    // remove the previous layer loaded via file layer
    this.mapService.removeAllLayers(this.mapService.map, this.mapService.fileLayerFeatureGroup);
    // zoom on layer
    this._mapListServive.zoomOnSelectedLayer(this.mapService.map, this.mapService.marker);
  }
}
