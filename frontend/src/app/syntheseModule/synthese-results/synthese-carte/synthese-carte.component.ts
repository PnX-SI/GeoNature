import {
  Component,
  OnInit,
  Input,
  AfterViewInit,
  EventEmitter,
  OnChanges,
  Output,
  Inject,
  OnDestroy,
} from '@angular/core';
import { takeUntil } from 'rxjs/operators';
import { Subject } from 'rxjs';

import { LangChangeEvent, TranslateService } from '@ngx-translate/core';
import { GeoJSON } from 'leaflet';
import * as L from 'leaflet';

import { MapListService } from '@geonature_common/map-list/map-list.service';
import { MapService } from '@geonature_common/map/map.service';
import { leafletDrawOption } from '@geonature_common/map/leaflet-draw.options';
import { CommonService } from '@geonature_common/service/common.service';
import { APP_CONFIG_TOKEN } from '@geonature_config/app.config';
import { SyntheseFormService } from '@geonature_common/form/synthese-form/synthese-form.service';


export type EventDisplayCriteria = {
  type: 'grid' | 'point',
  name?: string,
  field?: string,
}

type MapStyle = {
  color: string,
  weight?: number,
  fill?: boolean,
  fillOpacity?: number,
}

@Component({
  selector: 'pnx-synthese-carte',
  templateUrl: 'synthese-carte.component.html',
  styleUrls: ['synthese-carte.component.scss'],
  providers: [],
})
export class SyntheseCarteComponent implements OnInit, AfterViewInit, OnChanges, OnDestroy {
  public leafletDrawOptions = leafletDrawOption;
  public currentLeafletDrawCoord: any;
  public firstFileLayerMessage = true;
  public SYNTHESE_CONFIG = this.config.SYNTHESE;
  // set a new featureGroup - cluster or not depending of the synthese config
  public cluserOrSimpleFeatureGroup = this.config.SYNTHESE.ENABLE_LEAFLET_CLUSTER
    ? (L as any).markerClusterGroup()
    : new L.FeatureGroup();

  private destroy$: Subject<boolean> = new Subject<boolean>();

  private enableFitBounds = true;
  private mapLegend;

  private areasEnable;
  private areasLabelSwitchBtn;

  private defaultCriteriaCode = 'default';
  private areaAggregationCriteriaCode = 'area-aggregation';
  // TODO: create full Typescript object
  private selectedCriteria: { [key: string]: any } = {
    code: this.defaultCriteriaCode,
  };

  public selectedLayers: Array<L.Layer> = [];
  public layersDict: object = {};

  private originDefaultStyle: MapStyle = {
    color: '#3388FF',
    weight: 3,
    fill: false,
  };
  private selectedDefaultStyle: MapStyle = {
    color: '#FF0000',
  };
  private originAreasStyle: MapStyle = {
    color: '#FFFFFF',
    weight: 0.4,
    fillOpacity: 0.8,
  };
  private selectedAreasStyle: MapStyle = {
    color: '#FF0000',
    weight: 3,
  };

  @Input() inputSyntheseData: GeoJSON;
  @Output() onAreasToggle = new EventEmitter<EventDisplayCriteria>();

  constructor(
    @Inject(APP_CONFIG_TOKEN) private config,
    public mapListService: MapListService,
    private _ms: MapService,
    public formService: SyntheseFormService,
    private _commonService: CommonService,
    private translateService: TranslateService
  ) {
    this.areasEnable =
      this.config.SYNTHESE.ENABLE_AREA_AGGREGATION &&
      this.config.SYNTHESE.AREA_AGGREGATION_BY_DEFAULT;
  }

  ngOnInit() {
    this.leafletDrawOptions.draw.rectangle = true;
    this.leafletDrawOptions.draw.circle = true;
    this.leafletDrawOptions.draw.polyline = false;
    this.leafletDrawOptions.edit.remove = true;
  }

  ngOnDestroy() {
    this.destroy$.next(true);
    this.destroy$.unsubscribe();
  }

  ngAfterViewInit() {
    // event from the list
    // On table click, change style layer and zoom
    this.mapListService.onTableClick$.subscribe((id) => {
      const selectedLayers = this.layersDict[id];
      if (selectedLayers) {
        this.toggleStyleFromList(selectedLayers);
        const tempFeatureGroup = new L.FeatureGroup();
        selectedLayers.forEach((layer) => {
          tempFeatureGroup.addLayer(layer);
        });
        this._ms.map.fitBounds(tempFeatureGroup.getBounds(), { maxZoom: 18 });
      } else {
        this._commonService.regularToaster(
          'warning',
          "L'observation selectionnée n'est présente dans aucune maille - passez en mode 'point' pour la localiser"
        );
      }
    });

    // add the featureGroup to the map
    this.cluserOrSimpleFeatureGroup.addTo(this._ms.map);

    // Handle areas button, criteria list and legend
    if (this.config.SYNTHESE.ENABLE_AREA_AGGREGATION || this.config.SYNTHESE.MAP_CRITERIA_LIST) {
      if (this.config.SYNTHESE.MAP_CRITERIA_LIST) {
        this.addCriteriaList();
      } else {
        this.addAreasButton();
      }
      this.onLanguageChange();

      if (this.areasEnable) {
        this.addAreasLegend();
      } else {
        this.addCriteriaLegend();
      }
    }
  }

  private onLanguageChange() {
    // don't forget to unsubscribe!
    this.translateService.onLangChange
      .pipe(takeUntil(this.destroy$))
      .subscribe((langChangeEvent: LangChangeEvent) => {
        this.defineI18nMessages();
      });
  }

  private defineI18nMessages() {
    // Define default messages for datatable
    this.translateService
      .get('Synthese.Map.AreasToggleBtn')
      .subscribe((translatedTxt: string[]) => {
        this.areasLabelSwitchBtn.innerText = translatedTxt;
      });
  }

  addCriteriaList() {
    const DisplayCriteriaControl = L.Control.extend({
      options: {
        position: 'topright',
      },
      onAdd: (map) => {
        let criteriaContainer = L.DomUtil.create(
          'div',
          'leaflet-bar leaflet-control-layers custom-control leaflet-control-custom synthese-map-criteria'
        );
        criteriaContainer.setAttribute('aria-haspopup', 'true');
        L.DomEvent.disableClickPropagation(criteriaContainer);
        L.DomEvent.disableScrollPropagation(criteriaContainer);

        const collapseCriteriaList = (evt) => {
          if (!evt || !(evt.type === 'pointerleave' && evt['pointerType'] === 'touch')) {
            criteriaContainer.classList.remove('criteria-control-list-expanded');
          }
        };

        const expandCriteriaList = () => {
          criteriaContainer.classList.add('criteria-control-list-expanded');
        };

        L.DomEvent.on(
          criteriaContainer,
          {
            pointerenter: expandCriteriaList,
            pointerleave: collapseCriteriaList,
          },
          this
        );
        map.on('click', collapseCriteriaList);

        let criteriaBtn = L.DomUtil.create('a', 'criteria-control-toggle', criteriaContainer);
        criteriaBtn.href = '#';
        //criteriaBtn.role = 'button';
        L.DomEvent.disableClickPropagation(criteriaBtn);

        let section = L.DomUtil.create('section', 'criteria-control-list', criteriaContainer);

        // Add default display entry
        let label = L.DomUtil.create('label', '', section);
        let span = L.DomUtil.create('span', '', label);
        let inputBtn = L.DomUtil.create('input', 'criteria-control-selector', span);
        inputBtn.setAttribute('id', `criteria-radio-btn-${this.defaultCriteriaCode}`);
        inputBtn.setAttribute('name', 'criteria-radio-btn');
        inputBtn.setAttribute('type', 'radio');
        inputBtn.onchange = () => {
          if (inputBtn.checked) {
            this.selectedCriteria = {
              code: this.defaultCriteriaCode,
            };
          }
          this.activateMapDisplayCriteria();
        };
        inputBtn.checked = true;
        this.selectedCriteria = {
          code: this.defaultCriteriaCode,
        };
        let textLabelSpan = L.DomUtil.create('span', '', span);
        textLabelSpan.innerText =
          ' ' + this.translateService.instant(`Synthese.Map.Criteria.${this.defaultCriteriaCode}`);

        // Add observations area aggregation display entry
        if (this.config.SYNTHESE.ENABLE_AREA_AGGREGATION) {
          let label = L.DomUtil.create('label', '', section);
          let span = L.DomUtil.create('span', '', label);
          let inputBtn = L.DomUtil.create('input', 'criteria-control-selector', span);
          inputBtn.setAttribute('id', `criteria-radio-btn-${this.areaAggregationCriteriaCode}`);
          inputBtn.setAttribute('name', 'criteria-radio-btn');
          inputBtn.setAttribute('type', 'radio');
          inputBtn.onchange = () => {
            if (inputBtn.checked) {
              this.selectedCriteria = {
                code: this.areaAggregationCriteriaCode,
              };
            }
            console.log(`Criteria ${this.selectedCriteria.code} changed !`);
            this.activateMapDisplayCriteria();
          };
          if (this.config.SYNTHESE.AREA_AGGREGATION_BY_DEFAULT === true) {
            console.log(`Criteria ${this.selectedCriteria.code} default !`);
            inputBtn.checked = this.config.SYNTHESE.AREA_AGGREGATION_BY_DEFAULT;
            this.selectedCriteria = {
              code: this.areaAggregationCriteriaCode,
            };
          }
          let textLabelSpan = L.DomUtil.create('span', '', span);
          textLabelSpan.innerText =
            ' ' +
            this.translateService.instant(
              `Synthese.Map.Criteria.${this.areaAggregationCriteriaCode}`
            );
        }

        // Add criteria display list
        if (this.config.SYNTHESE.MAP_CRITERIA_LIST) {
          L.DomUtil.create('div', 'criteria-control-list-separator', section);

          const criteriaList = JSON.parse(JSON.stringify(this.config.SYNTHESE.MAP_CRITERIA_LIST));
          for (const criteriaCode in criteriaList) {
            const criteria = criteriaList[criteriaCode];
            criteria.code = criteriaCode;
            if (criteria.activate === false) {
              continue;
            }

            let label = L.DomUtil.create('label', '', section);
            let span = L.DomUtil.create('span', '', label);
            if (criteria.description) {
              span.setAttribute('title', criteria.description);
            }
            let inputBtn = L.DomUtil.create('input', 'criteria-control-selector', span);
            inputBtn.setAttribute('id', `criteria-radio-btn-${criteria.code}`);
            inputBtn.setAttribute('name', 'criteria-radio-btn');
            inputBtn.setAttribute('type', 'radio');
            inputBtn.onchange = () => {
              this.selectedCriteria = criteria;
              console.log(`Criteria ${criteria.code} changed !`);
              this.activateMapDisplayCriteria();
            };
            if (
              criteria.default === true &&
              this.config.SYNTHESE.AREA_AGGREGATION_BY_DEFAULT !== true
            ) {
              inputBtn.checked = criteria.default;
              this.selectedCriteria = criteria;
              this.prepareMarkerStyles();
              console.log(`Default ${criteria.code}!`);
            }
            let textLabelSpan = L.DomUtil.create('span', '', span);
            textLabelSpan.innerText = ` ${criteria.label}`;
          }
        }

        return criteriaContainer;
      },
    });

    const map = this._ms.getMap();
    map.addControl(new DisplayCriteriaControl());
  }

  addAreasButton() {
    const LayerControl = L.Control.extend({
      options: {
        position: 'topright',
      },
      onAdd: (map) => {
        let switchBtnContainer = L.DomUtil.create(
          'div',
          'leaflet-bar custom-control custom-switch leaflet-control-custom synthese-map-areas'
        );

        let switchBtn = L.DomUtil.create('input', 'custom-control-input', switchBtnContainer);
        switchBtn.id = 'toggle-areas-btn';
        switchBtn.type = 'checkbox';
        switchBtn.onclick = () => {
          this.selectedCriteria = {
            code: switchBtn.checked ? this.areaAggregationCriteriaCode : this.defaultCriteriaCode,
          };
          this.activateMapDisplayCriteria();
        };
        if (this.config.SYNTHESE.AREA_AGGREGATION_BY_DEFAULT === true) {
          switchBtn.checked = this.config.SYNTHESE.AREA_AGGREGATION_BY_DEFAULT;
        }

        this.areasLabelSwitchBtn = L.DomUtil.create(
          'label',
          'custom-control-label',
          switchBtnContainer
        );
        this.areasLabelSwitchBtn.setAttribute('for', 'toggle-areas-btn');
        this.areasLabelSwitchBtn.innerText = this.translateService.instant(
          'Synthese.Map.AreasToggleBtn'
        );

        return switchBtnContainer;
      },
    });

    const map = this._ms.getMap();
    map.addControl(new LayerControl());
  }

  private activateMapDisplayCriteria() {
    let event: EventDisplayCriteria = {
      type: 'point',
      name: this.selectedCriteria.code,
    };

    this.formService.selectors = this.formService.selectors.delete('with_field');
    this.formService.selectors = this.formService.selectors.delete('with_areas');
    if (this.selectedCriteria.code == this.areaAggregationCriteriaCode) {
      event.type = 'grid';
      this.formService.selectors = this.formService.selectors.set('with_areas', 'true');
    } else if (this.selectedCriteria.field) {
      this.formService.selectors = this.formService.selectors.set(
        'with_field',
        this.selectedCriteria.field
      );
      event.field = this.selectedCriteria.field;
    }
    if (this.selectedCriteria.values) {
      this.prepareMarkerStyles();
    }

    this.onAreasToggle.emit(event);

    this.addLegend();
  }

  private prepareMarkerStyles() {
    this.prepareCriteriaValues();

    let preparedMarkerStyles = {};
    this.selectedCriteria.preparedValues.forEach((item) => {
      let valuesList = Array.isArray(item.value) ? item.value : [item.value];
      valuesList.forEach((val) => {
        //delete item.value;
        //delete item.color;
        preparedMarkerStyles[val] = item;
      });
    });
    this.selectedCriteria.preparedMarkerStyles = preparedMarkerStyles;
    console.log('preparedMarkerStyles', preparedMarkerStyles);
  }

  private addLegend() {
    this.removeLegend();

    if (this.selectedCriteria.code == this.areaAggregationCriteriaCode) {
      this.addAreasLegend();
    } else if (this.selectedCriteria.code != this.defaultCriteriaCode) {
      this.addCriteriaLegend();
    }
    // Do not display legend for default display
  }

  private removeLegend() {
    const map = this._ms.getMap();
    if (this.mapLegend) {
      this.mapLegend.remove(map);
    }
    this.enableFitBounds = false;
  }

  private addCriteriaLegend() {
    this.prepareCriteriaLegend();

    this.mapLegend = new (L.Control.extend({
      options: { position: 'bottomright' },
    }))();

    const vm = this;
    this.mapLegend.onAdd = (map) => {
      let div = L.DomUtil.create('div', 'info legend');

      let labels = [`<strong> ${this.selectedCriteria.label} </strong>`];
      // loop through our density intervals and generate a label with a colored square for each interval
      for (var i = 0; i < this.selectedCriteria.preparedLegendStyles.length; i++) {
        let grade = this.selectedCriteria.preparedLegendStyles[i];
        if (grade.description) {
          labels.push(
            `<span title="${grade.description}">` +
              `<i style="${grade.css.join(';')}"></i> ${grade.label}` +
              '</span>'
          );
        } else {
          labels.push(`<i style="${grade.css.join(';')}"></i> ${grade.label}`);
        }
      }
      div.innerHTML = labels.join('<br>');

      return div;
    };

    const map = this._ms.getMap();
    this.mapLegend.addTo(map);
  }

  private prepareCriteriaLegend() {
    this.prepareCriteriaValues();

    let preparedLegendStyles = [];
    this.selectedCriteria.preparedValues.forEach((item) => {
      let legendItem = {
        label: item.label,
        description: item.description,
        css: [],
      };

      let styles = item.styles;

      // Compute legend fill color
      if (styles.fill && styles.fillOpacity != 0) {
        let backgroundColor = styles.fillColor;
        if (styles.fillOpacity < 1) {
          backgroundColor = this.convertColorHexToRgbA(styles.fillColor, styles.fillOpacity);
        }
        legendItem.css.push(`background-color: ${backgroundColor}`);
      }

      // Compute legend border
      if (styles.stroke && styles.opacity != 0 && styles.weight != 0) {
        let borderColor = styles.color;
        if (styles.opacity < 1) {
          borderColor = this.convertColorHexToRgbA(styles.color, styles.opacity);
        }
        legendItem.css.push(`border: ${styles.weight}px solid ${borderColor}`);
      }

      preparedLegendStyles.push(legendItem);
    });

    this.selectedCriteria.preparedLegendStyles = preparedLegendStyles;
    console.log('preparedLegendStyles', preparedLegendStyles);
  }

  private prepareCriteriaValues() {
    if (this.selectedCriteria.preparedValues) {
      return;
    }

    let defaultStyles = {
      stroke: true,
      color: '#3388ff',
      weight: 3,
      opacity: 1.0,
      fill: true,
      fillColor: '#3388ff',
      fillOpacity: 0.2,
    };
    let defaultCriteriaStyles = this.selectedCriteria.styles ? this.selectedCriteria.styles : {};
    let combinedStyles = {
      ...defaultStyles,
      ...this.getOriginDefaultStyle(),
      ...defaultCriteriaStyles,
    };

    // Add several values by geom entry
    this.selectedCriteria.values.push({
      value: '*',
      label: this.translateService.instant('Synthese.Map.SeveralValues'),
      color: '#ffffff',
      styles: { weight: 1, color: '#a9a9a9' },
    });

    // Compute values
    let preparedValues = [];
    this.selectedCriteria.values.forEach((item) => {
      item.value = Array.isArray(item.value) ? item.value : [item.value];
      item.styles = item.styles ? item.styles : {};

      let forceFillStyles = {
        fill: true,
        fillColor: item.color,
      };
      item.styles = { ...combinedStyles, ...item.styles, ...forceFillStyles };

      preparedValues.push(item);
    });

    this.selectedCriteria.preparedValues = preparedValues;
    console.log('preparedValues', preparedValues);
  }

  private convertColorHexToRgbA(hex, opacity = 1) {
    let c: any;
    if (/^#([A-Fa-f0-9]{3}){1,2}$/.test(hex)) {
      c = hex.substring(1).split('');
      if (c.length == 3) {
        c = [c[0], c[0], c[1], c[1], c[2], c[2]];
      }
      c = '0x' + c.join('');
      return 'rgba(' + [(c >> 16) & 255, (c >> 8) & 255, c & 255].join(',') + `,${opacity})`;
    }
    throw new Error('Bad Hex');
  }

  private addAreasLegend() {
    this.mapLegend = new (L.Control.extend({
      options: { position: 'bottomright' },
    }))();

    const vm = this;
    this.mapLegend.onAdd = (map) => {
      let div = L.DomUtil.create('div', 'info legend');
      let grades = this.config['SYNTHESE']['AREA_AGGREGATION_LEGEND_CLASSES']
        .map((legendClass) => legendClass.min)
        .reverse();
      let labels = ["<strong> Nombre <br> d'observations </strong>"];

      // loop through our density intervals and generate a label with a colored square for each interval
      for (var i = 0; i < grades.length; i++) {
        labels.push(
          '<i style="border-radius: 2px; background:' +
            vm.getColor(grades[i] + 1) +
            '"></i> ' +
            grades[i] +
            (grades[i + 1] ? '&ndash;' + grades[i + 1] : '+')
        );
      }
      div.innerHTML = labels.join('<br>');

      return div;
    };

    const map = this._ms.getMap();
    this.mapLegend.addTo(map);
  }

  ngOnChanges(change) {
    // Clear layerDict cache
    this.layersDict = {};

    // On change delete the previous layer and load the new ones from the geojson data send by the API.
    // Here we don't use geojson component for performance reasons.
    if (this._ms.map) {
      // Remove the whole featureGroup to avoid iterate over all its layer
      this._ms.map.removeLayer(this.cluserOrSimpleFeatureGroup);
    }

    if (change && change.inputSyntheseData.currentValue) {
      // Regenerate the featuregroup
      this.cluserOrSimpleFeatureGroup = this.config.SYNTHESE.ENABLE_LEAFLET_CLUSTER
        ? (L as any).markerClusterGroup({
            iconCreateFunction: this.overrideClusterCount,
          })
        : new L.FeatureGroup();

      const geojsonLayer = new L.GeoJSON(change.inputSyntheseData.currentValue, {
        pointToLayer: (feature, latlng) => {
          const circleMarker = L.circleMarker(latlng);
          let countObs = feature.properties.observations.id.length;
          (circleMarker as any).nb_obs = countObs;
          circleMarker.bindTooltip(`${countObs}`, {
            permanent: true,
            direction: 'center',
            offset: L.point({ x: 0, y: 0 }),
            className: 'number-obs',
          });

          return circleMarker;
        },
        style: this.styleFeature.bind(this),
        onEachFeature: this.onEachFeature.bind(this),
      });
      this.cluserOrSimpleFeatureGroup.addLayer(geojsonLayer);
      this._ms.map.addLayer(this.cluserOrSimpleFeatureGroup);

      // Zoom on extend after first search
      if (change.inputSyntheseData.previousValue !== undefined) {
        try {
          // Try to fit bound on layer. catch error if no layer in feature group
          if (this.enableFitBounds) {
            this._ms.map.fitBounds(this.cluserOrSimpleFeatureGroup.getBounds());
          } else {
            this.enableFitBounds = true;
          }
        } catch (error) {
          console.log('no layer in feature group');
        }
      }
    }
  }

  overrideClusterCount(cluster) {
    const obsChildCount = cluster
      .getAllChildMarkers()
      .map((layer) => {
        return layer.nb_obs;
      })
      .reduce((previous, next) => previous + next);
    const clusterSize = obsChildCount > 100 ? 'large' : obsChildCount > 10 ? 'medium' : 'small';
    return L.divIcon({
      html: `<div><span>${obsChildCount}</span></div>`,
      className: `marker-cluster marker-cluster-${clusterSize}`,
      iconSize: L.point(40, 40),
    });
  }

  onEachFeature(feature, layer) {
    //console.log("onEachFeature > feature", feature)
    // make a cache a layers in a dict with id key
    // TODO: change name, it's a observations cache used by synthese list and map !
    this.layerDictCache(feature.properties.observations, layer);

    this.layerEvent(layer, feature.properties.observations);
  }

  layerDictCache(observations, layer) {
    for (let id of observations.id) {
      id in this.layersDict ? this.layersDict[id].push(layer) : (this.layersDict[id] = [layer]);
    }
  }

  layerEvent(layer, observations) {
    layer.on({
      click: (e) => {
        this.toggleStyleFromMap(observations, layer);
        const idSyntheseIds = observations.id;
        console.log(`id synthese: ${idSyntheseIds}`);
        this.mapListService.mapSelected.next(idSyntheseIds);
        if (this.selectedCriteria.code == this.areaAggregationCriteriaCode) {
          this.bindAreasPopup(layer, idSyntheseIds);
        }
      },
    });
  }

  private styleFeature(feature) {
    //console.log("styleFeature", feature);
    // set style
    if (this.selectedCriteria.code == this.areaAggregationCriteriaCode) {
      return {
        ...this.originAreasStyle,
        ...{ fillColor: this.getColor(feature.properties.observations.id.length) },
      };
    } else if (this.selectedCriteria.code != this.defaultCriteriaCode) {
      return this.getCriteriaStyle(feature.properties.observations);
    }
  }

  private getColor(obsNbr) {
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

  private getCriteriaStyle(observations) {
    let criteriaStyle;
    const type = this.selectedCriteria.type;
    const values = this.getObservationsCriteriaValues(observations);

    let featureCriteriaValue = values.length > 1 ? '*' : values[0];
    if (type == 'nomenclatures' || featureCriteriaValue == '*') {
      criteriaStyle = this.selectedCriteria.preparedMarkerStyles[featureCriteriaValue];
    } else if (['classes', 'dates'].includes(type)) {
      const classes: string[] = Object.keys(this.selectedCriteria.preparedMarkerStyles);
      classes.splice(classes.indexOf('*'), 1);

      let sortedClasses: string[] | number[] = [];
      if (type == 'classes') {
        const numericClasses: number[] = classes.map(Number);
        sortedClasses = numericClasses.sort((a, b) => b - a);
        featureCriteriaValue = Number(featureCriteriaValue);
      } else {
        sortedClasses = classes.sort();
      }

      let classesNbr = sortedClasses.length;
      let lastIndex = classesNbr - 1;
      for (let i = 0; i < classesNbr; i++) {
        let classeValue = sortedClasses[i];
        if (i != lastIndex) {
          if (featureCriteriaValue > classeValue) {
            criteriaStyle = this.selectedCriteria.preparedMarkerStyles[classeValue];
          }
        } else {
          criteriaStyle = this.selectedCriteria.preparedMarkerStyles[classeValue];
        }
      }
    }
    return criteriaStyle;
  }

  private getObservationsCriteriaValues(observations) {
    const field = this.selectedCriteria.field;
    const values = observations[field] ? observations[field] : [];
    return values;
  }

  private toggleStyleFromMap(observations, layer) {
    console.log('toggleStyleFromMap > layer', layer);
    console.log('toggleStyleFromMap > observations', observations);

    // Restore initial style
    if (this.selectedLayers.length > 0) {
      this.selectedLayers.forEach((layer) => {
        (layer as L.GeoJSON).setStyle(this.getOriginStyle(layer));
      });
    }

    // Set selected style
    layer.setStyle(this.getSelectedStyle());
    this.selectedLayers = [layer];
  }

  private toggleStyleFromList(currentSelectedLayers) {
    // Restore inital style
    if (this.selectedLayers.length > 0) {
      this.selectedLayers.forEach((layer) => {
        (layer as L.GeoJSON).setStyle(this.getOriginStyle(layer));
      });
    }

    // Apply new selected layer
    this.selectedLayers = currentSelectedLayers;

    this.selectedLayers.forEach((layer) => {
      (layer as L.GeoJSON).setStyle(this.getSelectedStyle());
    });
  }

  private getOriginStyle(layer) {
    let originStyle = this.getOriginDefaultStyle();
    if (
      this.selectedCriteria.code != this.defaultCriteriaCode &&
      this.selectedCriteria.code != this.areaAggregationCriteriaCode
    ) {
      originStyle = this.getCriteriaStyle(layer.feature.properties.observations);
    }
    return originStyle;
  }

  private getOriginDefaultStyle() {
    return this.selectedCriteria.code == this.areaAggregationCriteriaCode
      ? this.originAreasStyle
      : this.originDefaultStyle;
  }

  private getSelectedStyle() {
    let selectedStyle =
      this.selectedCriteria.code == this.areaAggregationCriteriaCode
        ? this.selectedAreasStyle
        : this.selectedDefaultStyle;
    return selectedStyle;
  }

  private bindAreasPopup(layer, ids) {
    let popupContent = `<b>${ids.length} observation(s)</b>`;
    layer.bindPopup(popupContent).openPopup();
  }

  bindGeojsonForm(geojson) {
    this.formService.searchForm.controls.radius.setValue(geojson.properties['radius']);
    this.formService.searchForm.controls.geoIntersection.setValue(geojson);
    // set the current coord of the geojson to remove layer from filelayer component via the input removeLayer
    this.currentLeafletDrawCoord = geojson;
  }

  onFileLayerLoaded(geojson) {
    this.formService.searchForm.controls.geoIntersection.setValue(geojson);

    if (this.firstFileLayerMessage) {
      this._commonService.translateToaster('success', 'Map.FileLayerInfoSynthese');
    }
    this.firstFileLayerMessage = false;
  }

  deleteControlValue() {
    this.formService.searchForm.controls.geoIntersection.reset();
    this.formService.searchForm.controls.radius.reset();
  }
}
