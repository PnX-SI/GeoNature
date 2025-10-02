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
  public x: number;
  public y: number;
  public coordsInput = '';
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

   onCoordsInputChange(value: string) {
    const currentValue = value || '';
    this.coordsInput = currentValue;

    const tokens = currentValue
      .split(/[\s,]+/)
      .map((token) => token.trim())
      .filter((token) => token.length > 0);

    if (tokens.length < 2) {
      return;
    }

    const parsedY = this.normalizeCoordinate(tokens[0]);
    const parsedX = this.normalizeCoordinate(tokens[1]);

    if (parsedX === null || parsedY === null) {
      return;
    }

    this.x = parsedX;
    this.y = parsedY;
    this.coordsInput = this.formatCoordsInput(parsedY,parsedX );
  }

  private normalizeCoordinate(value: string | number | null | undefined): number | null {
    if (typeof value === 'number') {
      return Number.isFinite(value) ? value : null;
    }

    if (value === null || value === undefined) {
      return null;
    }

    const trimmed = String(value).trim();

    if (!trimmed) {
      return null;
    }

    const parsed = Number(trimmed);

    return Number.isFinite(parsed) ? parsed : null;
  }

  private formatCoordsInput(x: number, y: number): string {
    return `${x}, ${y}`;
  }

  setMarkerFromGps(x, y) {
    const parsedX = this.normalizeCoordinate(x);
    const parsedY = this.normalizeCoordinate(y);

    if (parsedX === null || parsedY === null) {
      return;
    }

    this.x = parsedX;
    this.y = parsedY;
    this.coordsInput = this.formatCoordsInput(parsedX, parsedY);

    super.generateMarkerAndEvent(x, y);
    // remove others layers
    this.mapService.removeAllLayers(this.mapService.map, this.mapService.leafletDrawFeatureGroup);
    // remove the previous layer loaded via file layer
    this.mapService.removeAllLayers(this.mapService.map, this.mapService.fileLayerFeatureGroup);
    // zoom on layer
    this._mapListServive.zoomOnSelectedLayer(this.mapService.map, this.mapService.marker);
  }
}
