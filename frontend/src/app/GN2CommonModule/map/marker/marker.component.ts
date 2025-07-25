import { Component, OnInit, Input, Output, EventEmitter, OnChanges } from '@angular/core';
import { Map, Marker, Icon } from 'leaflet';
import { BehaviorSubject } from 'rxjs';
import { filter } from 'rxjs/operators';
import { MapService } from '../map.service';
import * as L from 'leaflet';
import { CommonService } from '../../service/common.service';
import { ConfigService } from '@geonature/services/config.service';

const iconRetinaUrl = './marker-icon-2x.png';
const iconUrl = './marker-icon.png';
const shadowUrl = './marker-shadow.png';

export const CustomMarkerIcon = Icon.extend({
  options: {
    iconRetinaUrl: iconRetinaUrl,
    iconUrl: iconUrl,
    shadowUrl: shadowUrl,
    iconSize: [25, 41],
    iconAnchor: [12, 41],
    popupAnchor: [1, -34],
    tooltipAnchor: [16, -28],
    shadowSize: [41, 41],
  },
});

/**
 * Ce composant permet d'afficher un marker au clic sur la carte ainsi qu'un controleur permettant d'afficher/désafficher le marker.
 *
 * NB: Doit être utiliser à l'interieur d'une balise ``pnx-map``
 */
@Component({
  selector: 'pnx-marker',
  templateUrl: 'marker.component.html',
})
export class MarkerComponent implements OnInit, OnChanges {
  public map: Map;
  public previousCoord: Array<any>;
  private _coordinates: BehaviorSubject<Array<any>> = new BehaviorSubject(null);
  get coordinates(): Array<any> {
    return this._coordinates.getValue();
  }
  @Input('coordinates') set coordinates(value: Array<any>) {
    this._coordinates.next(value);
  }
  @Input() zoomToLocationLevel: number;
  /** Niveau de zoom à partir du quel on peut ajouter un marker sur la carte*/
  @Input() zoomLevel: number;
  /** Contrôle si le marker est activé par défaut au lancement du composant */
  @Input() defaultEnable = true;
  @Output() markerChanged = new EventEmitter<any>();
  constructor(
    public mapservice: MapService,
    private _commonService: CommonService,
    public config: ConfigService
  ) {}

  ngOnInit() {
    this.map = this.mapservice.map;
    this.zoomLevel = this.zoomLevel || this.config.MAPCONFIG.ZOOM_LEVEL_RELEVE;

    this.setMarkerLegend();
    // activation or not of the marker
    if (this.defaultEnable) {
      this.enableMarkerOnClick();
    } else {
      this.changeMarkerButtonColor(false);
    }

    this.mapservice.isMarkerEditing$.subscribe((isEditing) => {
      this.toggleEditing(isEditing);
    });

    //Observable pour gérer de l'affichage du marker
    this._coordinates
      .pipe(filter((coords) => this.map !== undefined && coords != null))
      .subscribe((coords) => {
        this.previousCoord = coords;
        this.generateMarkerAndEvent(coords[0], coords[1], false, true);
      });
  }

  setMarkerLegend() {
    // Marker
    const MarkerLegend = this.mapservice.addCustomLegend(
      'topleft',
      'markerLegend',
      'url(assets/images/location-pointer.png)'
    );
    this.map.addControl(new MarkerLegend());
    // custom the marker
    document.getElementById('markerLegend').style.backgroundColor = '#c8c8cc';
    L.DomEvent.disableClickPropagation(document.getElementById('markerLegend'));
    document.getElementById('markerLegend').onclick = () => {
      this.toggleEditing(true);
    };
  }

  enableMarkerOnClick() {
    this.map.on('click', (e: any) => {
      // check zoom level
      if (this.map.getZoom() < this.zoomLevel) {
        this._commonService.translateToaster('warning', 'Map.Messages.ZoomWarning');
      } else {
        this.generateMarkerAndEvent(e.latlng.lng, e.latlng.lat, true);
      }
    });
  }
  generateMarkerAndEvent(x, y, withEvents = true, zoomOnLayer = false) {
    if (this.mapservice.marker !== undefined) {
      this.mapservice.marker.remove();
      this.mapservice.marker = this.mapservice.createMarker(x, y, true).addTo(this.map);
      this.previousCoord = [x, y];
      this.markerMoveEvent(this.mapservice.marker);
    } else {
      this.mapservice.marker = this.mapservice.createMarker(x, y, true).addTo(this.map);
      this.markerMoveEvent(this.mapservice.marker);
    }
    // observable to send geojson
    // this.mapservice.firstLayerFromMap = false;

    const geojsonMarker = this.markerToGeojson(this.mapservice.marker.getLatLng());
    if (withEvents) {
      this.mapservice.setGeojsonCoord(geojsonMarker);
      this.markerChanged.emit(geojsonMarker);
    }

    if (zoomOnLayer) {
      this.mapservice.zoomOnMarker([x, y]);
    }
  }

  markerMoveEvent(marker: Marker) {
    marker.on('moveend', (event: L.LeafletMouseEvent) => {
      if (this.map.getZoom() < this.zoomLevel) {
        this._commonService.translateToaster('warning', 'Map.Messages.ZoomWarning');
        this.mapservice.marker.remove();
        this.mapservice.marker = this.mapservice.createMarker(
          this.previousCoord[0],
          this.previousCoord[1],
          true
        );
        this.map.addLayer(this.mapservice.marker);
        this.markerMoveEvent(this.mapservice.marker);
      } else {
        const geojsonCoord = this.markerToGeojson(this.mapservice.marker.getLatLng());
        this.mapservice.setGeojsonCoord(geojsonCoord);
        this.markerChanged.emit(geojsonCoord);
      }
    });
  }

  changeMarkerButtonColor(enable) {
    document.getElementById('markerLegend').style.backgroundColor = enable ? '#c8c8cc' : 'white';
  }

  toggleEditing(enable: boolean) {
    this.mapservice.editingMarker = enable;
    this.changeMarkerButtonColor(this.mapservice.editingMarker);

    if (!this.mapservice.editingMarker) {
      // disable event
      this.mapservice.map.off('click');
      if (this.mapservice.marker !== undefined) {
        this.mapservice.marker.off('moveend');
        this.map.removeLayer(this.mapservice.marker);
      }
    } else {
      this.mapservice.removeAllLayers(this.map, this.mapservice.leafletDrawFeatureGroup);
      this.mapservice.removeAllLayers(this.map, this.mapservice.fileLayerFeatureGroup);
      this.enableMarkerOnClick();
    }
  }

  markerToGeojson(latLng) {
    return { geometry: { type: 'Point', coordinates: [latLng.lng, latLng.lat] } };
  }

  ngOnChanges(changes) {
    if (this.map && changes.coordinates && changes.coordinates.currentValue) {
      const coords = changes.coordinates.currentValue;
      this.coordinates = coords;
    }
  }
}
