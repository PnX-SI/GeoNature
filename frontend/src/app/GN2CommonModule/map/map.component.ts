import { Component, Input, OnInit, ViewChild, Injectable } from '@angular/core';
import { MapService } from './map.service';
import { Map, LatLngExpression, LatLngBounds } from 'leaflet';
import { HttpClient, HttpParams } from '@angular/common/http';
import * as L from 'leaflet';
import { CommonService } from '../service/common.service';

import 'leaflet-draw';
import 'leaflet.locatecontrol';
import { UntypedFormControl } from '@angular/forms';
import { Observable, of } from 'rxjs';
import {
  catchError,
  debounceTime,
  distinctUntilChanged,
  tap,
  switchMap,
  map,
} from 'rxjs/operators';
import { ConfigService } from '@geonature/services/config.service';

const NOMINATIM_URL = 'https://nominatim.openstreetmap.org/search';

@Injectable()
export class NominatimService {
  PARAMS = null;

  constructor(
    private http: HttpClient,
    public config: ConfigService
  ) {
    this.PARAMS = new HttpParams({
      fromObject: {
        format: 'json',
        limit: '10',
        polygon_geojson: '1',
        countrycodes: this.config.MAPCONFIG.OSM_RESTRICT_COUNTRY_CODES,
      },
    });
  }

  search(term: string) {
    if (term === '') {
      return of([]);
    }

    return this.http
      .get(NOMINATIM_URL, { params: this.PARAMS.set('q', term) })
      .pipe(map((res) => res));
  }
}

/**
 * Ce composant affiche une carte Leaflet ainsi qu'un outil de recherche de lieux dits et d'adresses (basé sur l'API OpenStreetMap).
 * @example
 * <pnx-map height="80vh" [center]="center" [zoom]="zoom" > </pnx-map>`
 */
@Component({
  selector: 'pnx-map',
  templateUrl: './map.component.html',
  styleUrls: ['./map.component.scss'],
  providers: [NominatimService],
})
export class MapComponent implements OnInit {
  /**
   *  coordonnées du centrage de la carte: [long,lat]
   */
  @Input() center: Array<number>;
  /** Niveaux de zoom à l'initialisation de la carte */
  @Input() zoom: number = null;
  /** Hauteur de la carte (obligatoire) */
  @Input() height: string;

  /*@Input() mapContainer: string = 'map';*/

  /** Activer la barre de recherche */
  @Input() searchBar: boolean = true;

  /**Ajouter un bouton de géolocalisation */
  @Input() geolocation: boolean = false;

  @ViewChild('mapDiv', { static: true }) mapContainer;
  searchLocation: string;
  public searching = false;
  public searchFailed = false;
  public locationControl = new UntypedFormControl();
  public map: Map;
  constructor(
    private mapService: MapService,
    private _commonService: CommonService,
    private _nominatim: NominatimService,
    public config: ConfigService
  ) {
    this.searchLocation = '';
    this.zoom = this.config.MAPCONFIG.ZOOM_LEVEL;
  }

  ngOnInit() {
    this.initialize();
  }

  search = (text$: Observable<string>) =>
    text$.pipe(
      debounceTime(300),
      distinctUntilChanged(),
      tap(() => (this.searching = true)),
      switchMap((term) =>
        this._nominatim.search(term).pipe(
          tap(() => (this.searchFailed = false)),
          catchError(() => {
            this._commonService.translateToaster('Warning', 'Map.LocationError');
            this.searchFailed = true;
            return of([]);
          })
        )
      ),
      tap(() => (this.searching = false))
    );

  onResultSelected(nomatimObject) {
    let bounds: LatLngBounds;
    if (nomatimObject.item?.geojson) {
      const geojson = L.geoJSON(nomatimObject.item.geojson);
      bounds = geojson.getBounds();
    } else {
      const boundingBox: number[] = nomatimObject.item.boundingbox;
      bounds = L.latLngBounds(
        L.latLng(boundingBox[0], boundingBox[2]),
        L.latLng(boundingBox[1], boundingBox[3])
      );
    }
    this.map.fitBounds(bounds);
  }

  initialize() {
    let center: LatLngExpression = L.latLng(
      this.config.MAPCONFIG.CENTER[0],
      this.config.MAPCONFIG.CENTER[1]
    );
    if (this.center !== undefined) {
      center = L.latLng(this.center[0], this.center[1]);
    }

    // --- Create MAP
    this.map = L.map(this.mapContainer.nativeElement, {
      zoomControl: false,
      center: center,
      zoom: this.zoom,
      preferCanvas: true,
    });
    (this.map as any)._onResize();

    // --- MAP CONTROLS
    // ZOOM CONTROL
    L.control.zoom({ position: 'topright' }).addTo(this.map);

    // SCALE
    L.control.scale().addTo(this.map);

    //  GEOLOCATION
    if (this.geolocation && this.config.MAPCONFIG.GEOLOCATION) {
      (L.control as any).locate().addTo(this.map);
    }

    // --- LAYERS CONTROL
    // Baselayers
    const baseControl = {};
    const BASEMAP = JSON.parse(JSON.stringify(this.config.MAPCONFIG.BASEMAP));
    BASEMAP.forEach((basemap, index) => {
      const formatedBasemap = this.formatBaseMapConfig(basemap);
      if (basemap.service === 'wms') {
        baseControl[formatedBasemap.name] = L.tileLayer.wms(
          formatedBasemap.url,
          formatedBasemap.options
        );
      } else {
        baseControl[formatedBasemap.name] = L.tileLayer(
          formatedBasemap.url,
          formatedBasemap.options
        );
      }
    });
    // --- Layers selection
    // overlays layers
    const overlaysLayers = this.mapService.createOverLayers(this.map);
    // create control layers
    this.mapService.layerControl = L.control.layers(baseControl, overlaysLayers, {
      sortLayers: false, // When false, layers will keep the order in which they were added to the control
      collapsed: true, //If true, the control will be collapsed into an icon and expanded on mouse hover
    });
    this.mapService.layerControl.addTo(this.map);

    this.mapService.setMap(this.map);

    // ADD DRAW CONTROL
    this.mapService.initializeLeafletDrawFeatureGroup();

    // GET EXTEND ON EACH ZOOM
    this.map.on('moveend', (e) => {
      // keep current extend only if current zoom != 0
      if (this.map.getZoom() !== 0) {
        this.mapService.currentExtend = {
          center: this.map.getCenter(),
          zoom: this.map.getZoom(),
        };
      }
    });

    // on L.controler.layers add over layer to map
    this.map.on('overlayadd', (overlay) => {
      // once - load JSON or WFS overlay data async if not already loaded
      this.mapService.loadOverlay(overlay);
    });

    // Store last selected basemap
    this.map.on('baselayerchange', (layer) => {
      localStorage.setItem('MapLayer', layer.name);
    });

    // Select and add the current tile layer
    const userMapLayer = localStorage.getItem('MapLayer');
    if (userMapLayer !== null && baseControl[userMapLayer] !== undefined) {
      this.map.addLayer(baseControl[userMapLayer]);
    } else {
      this.map.addLayer(baseControl[BASEMAP[0].name]);
    }

    setTimeout(() => {
      this.map.invalidateSize();
    }, 50);
  }

  /** Retrocompatibility hack to format map config to the expected format:
   *
   {
    name: string,
    url: string,
    service?: wms|wmts|null
    options?: {
        layer?: string,
        attribution?: string,
        format?: string
        [...]
    }
  }
   */
  formatBaseMapConfig(baseMap) {
    // eslint-disable-next-line guard-for-in
    for (let attr in baseMap) {
      if (attr === 'layer') {
        baseMap['url'] = baseMap[attr];
        delete baseMap['layer'];
      }
      if (!['url', 'layer', 'name', 'service', 'options'].includes(attr)) {
        if (!baseMap['options']) {
          baseMap['options'] = {};
        }
        baseMap['options'][attr] = baseMap[attr];
        delete baseMap[attr];
      }
    }
    return baseMap;
  }

  formatter(nominatim) {
    return nominatim.display_name;
  }
}
