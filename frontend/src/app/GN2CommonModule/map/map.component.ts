import { Component, Input, OnInit, ViewChild, OnChanges } from '@angular/core';
import { MapService } from './map.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { Map, LatLngExpression } from 'leaflet';
import { AppConfig } from '@geonature_config/app.config';
import { Http } from '@angular/http';
import * as L from 'leaflet';
import { CommonService } from '../service/common.service';

import 'leaflet-draw';
import { FormControl } from '@angular/forms';
import { Observable } from 'rxjs';
import { of } from 'rxjs/observable/of';
import { catchError, debounceTime, distinctUntilChanged, tap, switchMap } from 'rxjs/operators';

/**
 * Ce composant affiche une carte Leaflet ainsi qu'un outil de recherche de lieux dits et d'adresses (basé sur l'API OpenStreetMap).
 * @example
 * <pnx-map [center]="center" [zoom]="zoom"> </pnx-map>`
 */
@Component({
  selector: 'pnx-map',
  templateUrl: './map.component.html',
  styleUrls: ['./map.component.scss']
})
export class MapComponent implements OnInit {
  /**
   *  coordonnées du centrage de la carte: [long,lat]
   */
  @Input() center: Array<number>;
  /** Niveaux de zoom à l'initialisation de la carte */
  @Input() zoom: number = AppConfig.MAPCONFIG.ZOOM_LEVEL;
  /** Hauteur de la carte (obligatoire) */
  @Input() height: string;
  /** Activer la barre de recherche */
  @Input() searchBar: boolean = true;
  searchLocation: string;
  public searching = false;
  public searchFailed = false;
  public locationControl = new FormControl();
  public map: Map;
  constructor(
    private mapService: MapService,
    private _commonService: CommonService,
    private _http: Http
  ) {
    this.searchLocation = '';
  }

  ngOnInit() {
    this.initialize();
  }

  searchNominatim(search) {
    return this._http
      .get(
        `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(
          search
        )}&format=json&limit=10&polygon_geojson=1`,
        { withCredentials: false }
      )
      .map(res => res.json());
  }

  search = (text$: Observable<string>) =>
    text$.pipe(
      debounceTime(300),
      distinctUntilChanged(),
      tap(() => (this.searching = true)),
      switchMap(term =>
        this.searchNominatim(term).pipe(
          tap(() => (this.searchFailed = false)),
          catchError(() => {
            this._commonService.translateToaster('Warning', 'Map.LocationError');

            return of([]);
          })
        )
      ),
      tap(() => (this.searching = false))
    );

  onResultSelected(nomatimObject) {
    const geojson = L.geoJSON(nomatimObject.item.geojson);
    this.map.fitBounds(geojson.getBounds());
  }

  initialize() {
    let center: LatLngExpression;
    if (this.center !== undefined) {
      center = L.latLng(this.center[0], this.center[1]);
    } else {
      center = L.latLng(AppConfig.MAPCONFIG.CENTER[0], AppConfig.MAPCONFIG.CENTER[1]);
    }

    const map = L.map('map', {
      zoomControl: false,
      center: center,
      zoom: this.zoom,
      preferCanvas: true
    });
    this.map = map;
    (map as any)._onResize();

    L.control.zoom({ position: 'topright' }).addTo(map);
    const baseControl = {};
    AppConfig.MAPCONFIG.BASEMAP.forEach((basemap, index) => {
      const configObj = (basemap as any).subdomains
        ? { attribution: basemap.attribution, subdomains: (basemap as any).subdomains }
        : { attribution: basemap.attribution };
      baseControl[basemap.name] = L.tileLayer(basemap.layer, configObj);
      if (index === 0) {
        map.addLayer(baseControl[basemap.name]);
      }
    });
    L.control.layers(baseControl).addTo(map);
    L.control.scale().addTo(map);

    this.mapService.setMap(map);
    this.mapService.initializeLeafletDrawFeatureGroup();
  }

  formatter(nominatim) {
    return nominatim.display_name;
  }
}
