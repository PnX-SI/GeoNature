import { CommonModule } from '@angular/common';
import { Component, OnDestroy, OnInit, ViewChild } from '@angular/core';
import { Router } from '@angular/router';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { GeojsonComponent } from '@geonature_common/map/geojson/geojson.component';
import { MapService } from '@geonature_common/map/map.service';
import { Feature, FeatureCollection, Geometry } from 'geojson';
import { Layer } from 'leaflet';
import { Subject } from 'rxjs';
import { map, takeUntil } from 'rxjs/operators';
import { HomeContentListObsFiltersComponent } from './home-content-list-obs-filters/home-content-list-obs-filters.component';
import { HomeContentListObsListComponent } from './home-content-list-obs-list/home-content-list-obs-list.component';

interface HomeContentListObservationItem {
  id_synthese: number;
  cd_nom?: number | null;
  nom_vern_or_lb_nom: string;
  date_min: string | null;
  observers: string | null;
  geometry?: Geometry;
}

type HomeContentListObservationFeature = Feature<Geometry, HomeContentListObservationItem>;
type HomeContentListObservationFeatureCollection = FeatureCollection<Geometry, HomeContentListObservationItem>;

interface HomeContentListObsFilters {
  taxonomy_group2_inpn?: string[];
  taxonomy_group3_inpn?: string[];
}

@Component({
  standalone: true,
  selector: 'pnx-home-content-list-obs',
  templateUrl: './home-content-list-obs.component.html',
  styleUrls: ['./home-content-list-obs.component.scss'],
  imports: [CommonModule, GN2CommonModule, HomeContentListObsFiltersComponent, HomeContentListObsListComponent],
})
export class HomeContentListObsComponent implements OnInit, OnDestroy {
  @ViewChild(GeojsonComponent) private _geojsonComponent?: GeojsonComponent;

  readonly pageSize = 9;
  readonly defaultMapFeatureStyle = {
    color: '#3388FF',
    weight: 3,
    fill: false,
    radius: 6,
  };
  readonly selectedMapFeatureStyle = {
    color: '#FF0000',
    weight: 3,
    fill: false,
    radius: 6,
  };

  observations: HomeContentListObservationItem[] = [];
  observationsGeoJson: HomeContentListObservationFeatureCollection = {
    type: 'FeatureCollection',
    features: [],
  };
  isLoading = false;
  filters: HomeContentListObsFilters = {};
  currentPage = 0;
  selectedObservationId: number | null = null;

  private featureLayers = new Map<number, Layer>();
  private selectedLayer: Layer | null = null;
  private taxonThumbnailUrls = new Map<number, string | null>();
  private loadingTaxonThumbnailIds = new Set<number>();
  private destroy$ = new Subject<void>();

  constructor(
    private _syntheseDataService: SyntheseDataService,
    private _dataFormService: DataFormService,
    private _mapService: MapService,
    private _router: Router
  ) {}

  ngOnInit() {
    this._fetchObservations();
  }

  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }

  onFiltersChange(filters: HomeContentListObsFilters) {
    this.filters = filters;
    this.currentPage = 0;
    this._clearSelection(false);
    this._fetchObservations();
  }

  onPageChange(offset: number) {
    this.currentPage = offset;
  }

  onObservationSelect(idSynthese: number) {
    if (this.selectedObservationId === idSynthese) {
      this._clearSelection(true);
      return;
    }

    this._showObservationPage(idSynthese);
    this._selectObservation(idSynthese, true, true);
  }

  readonly onEachFeature = (feature: HomeContentListObservationFeature, layer: Layer) => {
    const idSynthese = feature.properties.id_synthese;
    this.featureLayers.set(idSynthese, layer);
    this._applyStyleToLayer(layer, this.defaultMapFeatureStyle);

    if ('bindPopup' in layer && typeof layer.bindPopup === 'function') {
      layer.bindPopup(this._buildPopupContent(feature.properties));
    }

    if (idSynthese === this.selectedObservationId) {
      this.selectedLayer = layer;
      this._applyStyleToLayer(layer, this.selectedMapFeatureStyle);
    }

    if ('on' in layer && typeof layer.on === 'function') {
      layer.on('click', () => {
        if (this.selectedObservationId === idSynthese) {
          this._clearSelection(true);
          return;
        }

        this._showObservationPage(idSynthese);
        this._selectObservation(idSynthese, false, false);
      });
    }
  };

  private _fetchObservations() {
    this.isLoading = true;
    this.featureLayers.clear();
    this.selectedLayer = null;
    this._syntheseDataService
      .getSyntheseData(this.filters, { limit: 100, format: 'ungrouped_geom' })
      .pipe(
        map(
          (data) =>
            ((data?.features ?? []) as HomeContentListObservationFeature[]).sort((a, b) => {
              const aTime = a.properties?.date_min ? new Date(a.properties.date_min).getTime() : 0;
              const bTime = b.properties?.date_min ? new Date(b.properties.date_min).getTime() : 0;
              return bTime - aTime;
            })
        ),
        takeUntil(this.destroy$)
      )
      .subscribe({
        next: (features: HomeContentListObservationFeature[]) => {
          this.observations = features.map((feature) => ({
            ...feature.properties,
            geometry: feature.geometry ?? undefined,
          }));
          this.observationsGeoJson = {
            type: 'FeatureCollection',
            features: features.filter((feature) => !!feature.geometry),
          };
          this._prefetchTaxonThumbnails();
          this.isLoading = false;
        },
        error: () => {
          this.observations = [];
          this.observationsGeoJson = {
            type: 'FeatureCollection',
            features: [],
          };
          this.isLoading = false;
        },
      });
  }

  private _prefetchTaxonThumbnails() {
    const taxonIds = new Set(
      this.observations
        .map((observation) => observation.cd_nom)
        .filter((cdNom): cdNom is number => typeof cdNom === 'number')
    );

    taxonIds.forEach((cdNom) => {
      if (this.taxonThumbnailUrls.has(cdNom) || this.loadingTaxonThumbnailIds.has(cdNom)) {
        return;
      }

      this.loadingTaxonThumbnailIds.add(cdNom);
      this._dataFormService
        .getTaxonInfo(cdNom, ['medias', 'cd_nom'])
        .pipe(takeUntil(this.destroy$))
        .subscribe({
          next: (taxonAttrAndMedias) => {
            const media = taxonAttrAndMedias['medias']?.find(
              (m) => m.id_type == this._syntheseDataService.config.TAXHUB.ID_TYPE_MAIN_PHOTO
            );
            const mediaUrl = media
              ? `${this._dataFormService.getTaxhubAPI()}/tmedias/thumbnail/${media.id_media}?h=96&w=96`
              : null;
            this.taxonThumbnailUrls.set(cdNom, mediaUrl);
            this.loadingTaxonThumbnailIds.delete(cdNom);
            this._refreshPopupContentsForTaxon(cdNom);
          },
          error: () => {
            this.taxonThumbnailUrls.set(cdNom, null);
            this.loadingTaxonThumbnailIds.delete(cdNom);
          },
        });
    });
  }

  private _refreshPopupContentsForTaxon(cdNom: number) {
    this.observations
      .filter((observation) => observation.cd_nom === cdNom)
      .forEach((observation) => {
        const layer = this.featureLayers.get(observation.id_synthese);
        if (!layer || !('setPopupContent' in layer) || typeof layer.setPopupContent !== 'function') {
          return;
        }

        layer.setPopupContent(this._buildPopupContent(observation));
      });
  }

  private _showObservationPage(idSynthese: number) {
    const observationIndex = this.observations.findIndex(
      (observation) => observation.id_synthese === idSynthese
    );
    if (observationIndex < 0) {
      return;
    }

    this.currentPage = Math.floor(observationIndex / this.pageSize);
  }

  private _clearSelection(shouldClosePopup: boolean) {
    this.selectedObservationId = null;

    if (!this.selectedLayer) {
      return;
    }

    this._applyStyleToLayer(this.selectedLayer, this.defaultMapFeatureStyle);

    if (shouldClosePopup && 'closePopup' in this.selectedLayer && typeof this.selectedLayer.closePopup === 'function') {
      this.selectedLayer.closePopup();
    }

    this.selectedLayer = null;
  }

  private _selectObservation(idSynthese: number, shouldOpenPopup: boolean, shouldCenterMap: boolean) {
    this.selectedObservationId = idSynthese;

    if (this.selectedLayer) {
      this._applyStyleToLayer(this.selectedLayer, this.defaultMapFeatureStyle);
    }

    const layer = this.featureLayers.get(idSynthese);
    if (!layer) {
      this.selectedLayer = null;
      return;
    }

    this.selectedLayer = layer;
    this._applyStyleToLayer(layer, this.selectedMapFeatureStyle);
    this._focusLayer(layer, shouldOpenPopup, shouldCenterMap);
  }

  private _applyStyleToLayer(layer: Layer, style) {
    if ('setStyle' in layer && typeof layer.setStyle === 'function') {
      layer.setStyle(style);
    }
  }

  private _focusLayer(layer: Layer, shouldOpenPopup: boolean, shouldCenterMap: boolean) {
    const currentGeojson = this._geojsonComponent?.currentGeojson as any;

    const finalizeFocus = () => {
      if (shouldCenterMap) {
        this._centerMapOnLayer(layer);
      }

      if ('openPopup' in layer && typeof layer.openPopup === 'function' && shouldOpenPopup) {
        layer.openPopup();
      }
    };

    if (
      currentGeojson &&
      typeof currentGeojson.zoomToShowLayer === 'function' &&
      typeof currentGeojson.hasLayer === 'function' &&
      currentGeojson.hasLayer(layer)
    ) {
      currentGeojson.zoomToShowLayer(layer, finalizeFocus);
      return;
    }

    finalizeFocus();
  }

  private _centerMapOnLayer(layer: Layer) {
    const map = this._mapService.map;
    if (!map) {
      return;
    }

    if ('getLatLng' in layer && typeof layer.getLatLng === 'function') {
      map.panTo(layer.getLatLng());
      return;
    }

    if ('getBounds' in layer && typeof layer.getBounds === 'function') {
      const bounds = layer.getBounds();
      if (bounds && bounds.isValid && bounds.isValid()) {
        map.fitBounds(bounds, { maxZoom: 14 });
      }
    }
  }

  private _buildPopupContent(observation: HomeContentListObservationItem): string {
    const url = new URL(window.location.href);
    url.hash = this._router.serializeUrl(
      this._router.createUrlTree(['synthese', 'occurrence', observation.id_synthese, 'details'])
    );

    const thumbnailUrl =
      typeof observation.cd_nom === 'number'
        ? this.taxonThumbnailUrls.get(observation.cd_nom) ?? ''
        : '';

    return `
      <div style="display:flex; align-items:flex-start; gap:0.75rem;">
        ${thumbnailUrl ? `<img src="${thumbnailUrl}" alt="" style="width:2.5rem; height:2.5rem; object-fit:cover; border-radius:0.25rem; flex:0 0 2.5rem;" />` : ''}
        <span>
          ${observation.nom_vern_or_lb_nom ?? ''} <br>
          <b> Observé le: </b> ${observation.date_min ?? ''} <br>
          <b> Par</b>: ${observation.observers ?? ''} <br>
          <a href="${url.href}">Voir l'observation</a>
        </span>
      </div>
    `;
  }
}
