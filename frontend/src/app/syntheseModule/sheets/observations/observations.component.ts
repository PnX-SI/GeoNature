import { Component, OnInit, OnDestroy } from '@angular/core';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { CommonModule } from '@angular/common';
import { MapListService } from '@geonature_common/map-list/map-list.service';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { FeatureCollection } from 'geojson';

import { ConfigService } from '@geonature/services/config.service';
import * as L from 'leaflet';
import { SyntheseFormService } from '@geonature_common/form/synthese-form/synthese-form.service';
import { TranslateService } from '@ngx-translate/core';
import { MapService } from '@geonature_common/map/map.service';
import { MatSliderModule } from '@angular/material/slider';
import { Loadable } from '../../sheets/loadable';
import { finalize } from 'rxjs/operators';
import { CommonService } from '@geonature_common/service/common.service';
import { Router } from '@angular/router';
import { Filters, ObservationsFiltersService, YearInterval } from './observations-filters.service';
import { SyntheseCriteriaService } from '@geonature/syntheseModule/services/criteria.service';

@Component({
  standalone: true,
  selector: 'observations',
  templateUrl: 'observations.component.html',
  styleUrls: ['observations.component.scss'],
  imports: [GN2CommonModule, CommonModule, MatSliderModule],
  // Own instances so switching display mode on this map never mutates the
  // SyntheseFormService.selectors singleton shared with the main Synthese
  // search page (synthese.module.ts) — that leakage used to survive SPA
  // navigation back to the main map until a full reload reset it.
  providers: [SyntheseCriteriaService, SyntheseFormService],
})
export class ObservationsComponent extends Loadable implements OnInit, OnDestroy {
  styleTabGeoJson: any = {};

  yearInterval: YearInterval | null = null;
  yearIntervalBoundaries: YearInterval | null = null;

  public criteriaActivatedSubscription;
  private mapLegend;

  constructor(
    private _syntheseDataService: SyntheseDataService,
    public mapListService: MapListService,
    public config: ConfigService,
    public formService: SyntheseFormService,
    public translateService: TranslateService,
    private _ms: MapService,
    private _commonService: CommonService,
    private _router: Router,
    private _os: ObservationsFiltersService,
    private criteriaService: SyntheseCriteriaService
  ) {
    super();
  }

  formatLabel(value: number): string {
    return `${value}`;
  }

  ngOnInit() {
    this._os.filters.subscribe((filters: Filters | null) => {
      if (filters == null) {
        this.styleTabGeoJson = undefined;
        this.clearObservationLayers();
        return;
      } else {
        this.updateObservations();
      }
    });

    this._os.yearIntervalBoundaries.subscribe((boundaries: YearInterval | null) => {
      // reset boundaries
      this.yearIntervalBoundaries = boundaries;
      this.yearInterval = boundaries ? { ...boundaries } : null;
    });
    this.initializeFormWithMapParams();
  }

  ngAfterViewInit() {
    this.addCriteriaMapLegend();
    this.subscribeToCriteriaActivated();
  }

  ngOnDestroy(): void {
    if (this.criteriaActivatedSubscription) {
      this.criteriaActivatedSubscription.unsubscribe();
    }
  }

  updateObservations() {
    this.startLoading();

    const format = this.criteriaService.isAreasAggDisplay()
      ? 'grouped_geom_by_areas'
      : 'grouped_geom';

    const filters: Filters = this._os.filters.getValue();
    if (this.yearInterval) {
      filters.date_min = `${this.yearInterval.min}-01-01`;
      filters.date_max = `${this.yearInterval.max}-12-31`;
    }
    const limit = this.criteriaService.isAreasAggDisplay() ? -1 : undefined;
    const selectors: any = { format, limit };
    if (this.criteriaService.isCriteriaDisplay()) {
      selectors.with_field = this.criteriaService.getCurrentField();
    }
    this._syntheseDataService
      .getSyntheseData({ ...filters }, selectors)
      .pipe(finalize(() => this.stopLoading()))
      .subscribe((data) => {
        if (!this.criteriaService.isAreasAggDisplay() && this._os.isSuperiorToSyntheseLimit) {
          this._commonService.regularToaster(
            'warning',
            `Pour des raisons de performances, le nombre d'observations affichées est limité à ${this.config['SYNTHESE']['NB_MAX_OBS_MAP']}`
          );
        }
        this.styleTabGeoJson = undefined;
        this.clearObservationLayers();

        if (data) {
          const geoJSON = L.geoJSON(data, {
            pointToLayer: (feature, latlng) => L.circleMarker(latlng, { radius: 10 }),
            style: this.styleFeature.bind(this),
            onEachFeature: this.onEachFeature.bind(this),
          });

          this._ms.map.addLayer((L as any).markerClusterGroup().addLayer(geoJSON));
          this._ms.map.fitBounds(geoJSON.getBounds());
        }
      });
  }

  private styleFeature(feature) {
    if (this.criteriaService.isAreasAggDisplay()) {
      return {
        ...this.criteriaService.originAreasStyle,
        fillColor: this.criteriaService.getColor(feature.properties.observations.length),
      };
    } else if (this.criteriaService.isCriteriaDisplay()) {
      return this.criteriaService.getCriteriaStyle(feature.properties.observations);
    }
  }

  onEachFeature(feature, layer) {
    const observations = feature.properties.observations;
    let popupContent = '';

    if (observations && observations.length > 0) {
      if (this.criteriaService.isAreasAggDisplay() && feature.geometry.type === 'MultiPolygon') {
        popupContent = `${observations.length} observations`;
      } else {
        const url = new URL(window.location.href);
        url.hash = this._router.serializeUrl(
          this._router.createUrlTree(['synthese', 'occurrence', observations[0].id_synthese])
        );
        popupContent = `
          ${observations[0].nom_vern_or_lb_nom || ''}<br>
          <b>Observé le :</b> ${observations[0].date_min || 'Non défini'}<br>
          <b>Par :</b> ${observations[0].observers || 'Non défini'}<br>
          <a href="${url.href}">Lien vers l'observation</a>`;
      }

      layer.bindPopup(popupContent);

      layer.on('click', function () {
        this.openPopup();
      });
    }
  }

  private initializeFormWithMapParams() {
    this.formService.searchForm.patchValue({
      format: this.criteriaService.isAreasAggDisplay() ? 'grouped_geom_by_areas' : 'grouped_geom',
    });
  }

  private addCriteriaMapLegend() {
    this.removeCriteriaMapLegend();
    const onAddFunc = this.criteriaService.buildLegendControl();

    if (onAddFunc) {
      const LegendControl = L.Control.extend({
        options: {
          position: 'bottomright',
        },
        onAdd: onAddFunc,
      });

      const map = this._ms.getMap();
      this.mapLegend = new LegendControl();
      this.mapLegend.addTo(map);
    }
  }

  private removeCriteriaMapLegend() {
    if (this.mapLegend) {
      this.mapLegend.remove();
    }
  }

  private subscribeToCriteriaActivated() {
    this.criteriaActivatedSubscription = this.criteriaService.onCriteriaActivated.subscribe(() => {
      this.addCriteriaMapLegend();
      this.updateObservations();
    });
  }

  private clearObservationLayers() {
    const map = this._ms.map;
    if (!map) return;
    map.eachLayer((layer) => {
      if (!(layer instanceof L.TileLayer)) {
        map.removeLayer(layer);
      }
    });
  }
}
