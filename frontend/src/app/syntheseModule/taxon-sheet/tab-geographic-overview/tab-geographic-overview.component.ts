import { Component, OnInit } from '@angular/core';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { CommonModule } from '@angular/common';
import { MapListService } from '@geonature_common/map-list/map-list.service';
import { Taxon } from '@geonature_common/form/taxonomy/taxonomy.component';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { FeatureCollection } from 'geojson';
import { TaxonSheetService } from '../taxon-sheet.service';
import { ConfigService } from '@geonature/services/config.service';
import * as L from 'leaflet';
import { SyntheseFormService } from '@geonature_common/form/synthese-form/synthese-form.service';
import { TranslateService } from '@ngx-translate/core';
import { MapService } from '@geonature_common/map/map.service';
import { MatSliderModule } from '@angular/material/slider';

interface MapAreasStyle {
  color: string;
  weight: number;
  fillOpacity: number;
  fillColor?: string;
}

interface YearInterval {
  min: number;
  max: number;
}

@Component({
  standalone: true,
  selector: 'tab-geographic-overview',
  templateUrl: 'tab-geographic-overview.component.html',
  styleUrls: ['tab-geographic-overview.component.scss'],
  imports: [GN2CommonModule, CommonModule, MatSliderModule],
})
export class TabGeographicOverviewComponent implements OnInit {
  observations: FeatureCollection | null = null;
  areasEnable: boolean;
  areasLegend: any;
  taxon: Taxon | null = null;
  private _areasLabelSwitchBtn;
  styleTabGeoJson: {};

  readonly YEAR_INTERVAL: YearInterval = {
    min: 1970,
    max: 2025,
  };
  yearInterval: YearInterval = { ...this.YEAR_INTERVAL };

  mapAreasStyle: MapAreasStyle = {
    color: '#FFFFFF',
    weight: 0.4,
    fillOpacity: 0.8,
  };

  mapAreasStyleActive: MapAreasStyle = {
    color: '#FFFFFF',
    weight: 0.4,
    fillOpacity: 0,
  };

  constructor(
    private _syntheseDataService: SyntheseDataService,
    private _tss: TaxonSheetService,
    public mapListService: MapListService,
    public config: ConfigService,
    public formService: SyntheseFormService,
    public translateService: TranslateService,
    private _ms: MapService
  ) {
    this.areasEnable =
      this.config.SYNTHESE.AREA_AGGREGATION_ENABLED &&
      this.config.SYNTHESE.AREA_AGGREGATION_BY_DEFAULT;
  }

  formatLabel(value: number): string {
    return `${value}`;
  }

  ngOnInit() {
    this._tss.taxon.subscribe((taxon: Taxon | null) => {
      this.taxon = taxon;
      if (!taxon) {
        this.observations = null;
        return;
      }
      this.updateTabGeographic();
    });
    this.initializeFormWithMapParams();
  }

  updateTabGeographic() {
    const format = this.areasEnable ? 'grouped_geom_by_areas' : 'grouped_geom';
    const date_min = `${this.yearInterval.min}-01-01`;
    const date_max = `${this.yearInterval.max}-12-31`;

    this._syntheseDataService
      .getSyntheseData(
        {
          cd_ref: [this.taxon.cd_ref],
          date_min: date_min,
          date_max: date_max,
        },
        { format }
      )
      .subscribe((data) => {
        this.observations = data;
        console.log(this.observations);
        this.styleTabGeoJson = undefined;

        const map = this._ms.getMap();

        map.eachLayer((layer) => {
          if (!(layer instanceof L.TileLayer)) {
            map.removeLayer(layer);
          }
        });

        if (this.observations && this.areasEnable) {
          L.geoJSON(this.observations, {
            onEachFeature: (feature, layer) => {
              const observations = feature.properties.observations;
              if (observations && observations.length > 0) {
                const obsCount = observations.length;
                this.setAreasStyle(layer as L.Path, obsCount);
              }
            },
          }).addTo(map);
        }
      });
  }
  private initializeFormWithMapParams() {
    this.formService.searchForm.patchValue({
      format: this.areasEnable ? 'grouped_geom_by_areas' : 'grouped_geom',
    });
  }

  ngAfterViewInit() {
    this.addAreasButton();
    if (this.areasEnable) {
      this.addAreasLegend();
    }
  }

  addAreasButton() {
    const LayerControl = L.Control.extend({
      options: {
        position: 'topright',
      },
      onAdd: (map) => {
        let switchBtnContainer = L.DomUtil.create(
          'div',
          'leaflet-bar custom-control custom-switch leaflet-control-custom tab-geographic-overview'
        );

        let switchBtn = L.DomUtil.create('input', 'custom-control-input', switchBtnContainer);
        switchBtn.id = 'toggle-areas-btn';
        switchBtn.type = 'checkbox';
        switchBtn.checked = this.config.SYNTHESE.AREA_AGGREGATION_BY_DEFAULT;

        switchBtn.onclick = () => {
          this.areasEnable = switchBtn.checked;
          this.updateTabGeographic();

          if (this.areasEnable) {
            this.addAreasLegend();
          } else {
            this.removeAreasLegend();
          }
        };

        this._areasLabelSwitchBtn = L.DomUtil.create(
          'label',
          'custom-control-label',
          switchBtnContainer
        );
        this._areasLabelSwitchBtn.setAttribute('for', 'toggle-areas-btn');
        this._areasLabelSwitchBtn.innerText = this.translateService.instant(
          'Synthese.Map.AreasToggleBtn'
        );

        return switchBtnContainer;
      },
    });

    const map = this._ms.getMap();
    map.addControl(new LayerControl());
  }

  private addAreasLegend() {
    if (this.areasLegend) return;
    this.areasLegend = new (L.Control.extend({
      options: { position: 'bottomright' },
    }))();

    this.areasLegend.onAdd = (map: L.Map): HTMLElement => {
      let div: HTMLElement = L.DomUtil.create('div', 'info legend');
      let grades: number[] = this.config['SYNTHESE']['AREA_AGGREGATION_LEGEND_CLASSES']
        .map((legendClass: { min: number; color: string }) => legendClass.min)
        .reverse();
      let labels: string[] = ["<strong> Nombre <br> d'observations </strong> <br>"];

      for (let i = 0; i < grades.length; i++) {
        labels.push(
          '<i style="background:' +
            this.getColor(grades[i] + 1) +
            '"></i> ' +
            grades[i] +
            (grades[i + 1] ? '&ndash;' + grades[i + 1] + '<br>' : '+')
        );
      }
      div.innerHTML = labels.join('<br>');

      return div;
    };

    const map = this._ms.getMap();
    this.areasLegend.addTo(map);
  }

  private removeAreasLegend() {
    if (this.areasLegend) {
      const map = this._ms.getMap();
      map.removeControl(this.areasLegend);
      this.areasLegend = null;
    }
  }

  private setAreasStyle(layer: L.Path, obsNbr: number) {
    this.mapAreasStyle['fillColor'] = this.getColor(obsNbr);
    layer.setStyle(this.mapAreasStyle);
    delete this.mapAreasStyle['fillColor'];
    this.styleTabGeoJson = this.mapAreasStyleActive;
  }

  private getColor(obsNbr: number) {
    let classesNbr = this.config['SYNTHESE']['AREA_AGGREGATION_LEGEND_CLASSES'].length;
    let lastIndex = classesNbr - 1;
    for (let i = 0; i < classesNbr; i++) {
      let legendClass = this.config['SYNTHESE']['AREA_AGGREGATION_LEGEND_CLASSES'][i];
      if (i != lastIndex) {
        if (obsNbr > legendClass.min) {
          return legendClass.color;
        }
      } else {
        return legendClass.color;
      }
    }
  }
}
