import { Injectable, OnDestroy } from '@angular/core';

import * as L from 'leaflet';
import { TranslateService } from '@librairies/@ngx-translate/core';
import { Subject } from '@librairies/rxjs';
import { map, takeUntil } from '@librairies/rxjs/operators';

import { ConfigService } from '@geonature/services/config.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { SyntheseFormService } from '@geonature_common/form/synthese-form/synthese-form.service';

export type EventDisplayCriteria = {
  type: 'grid' | 'point';
  name?: string;
  field?: string;
};

type MapStyle = {
  color: string;
  weight?: number;
  fill?: boolean;
  fillOpacity?: number;
};

@Injectable()
export class SyntheseCriteriaService implements OnDestroy {
  private originDefaultStyle: MapStyle = {
    color: '#3388FF', // Blue
    weight: 3,
    fill: false,
  };
  private selectedDefaultStyle: MapStyle = {
    color: '#FF0000', // Red
  };
  public originAreasStyle: MapStyle = {
    color: '#FFFFFF', // White
    weight: 0.4,
    fillOpacity: 0.8,
  };
  private selectedAreasStyle: MapStyle = {
    color: '#FF0000', // Red
    weight: 3,
  };
  // Leaflet's default fillOpacity fallback for Path/CircleMarker, used as the
  // unselected fill opacity in criteria mode.
  private criteriaOriginFillOpacity = 0.2;

  private criteriaConfig;
  private nomenclatures;
  private defaultCriteriaCode = 'default';
  private areaAggregationCriteriaCode = 'area-aggregation';
  // TODO: create full Typescript object
  private selectedCriteria: { [key: string]: any } = {
    code: this.defaultCriteriaCode,
  };

  public onCriteriaActivated = new Subject<EventDisplayCriteria>();
  private destroy$: Subject<boolean> = new Subject<boolean>();

  constructor(
    private config: ConfigService,
    private dataFormService: DataFormService,
    private formService: SyntheseFormService,
    private translateService: TranslateService
  ) {
    this.parseCriteriaConfig();
    this.extractNomenclatures();
    this.selectDefaultCriteria();
    this.initializeQueryParams();
  }

  private parseCriteriaConfig() {
    if (this.config.SYNTHESE.MAP_CRITERIA_LIST) {
      this.criteriaConfig = JSON.parse(JSON.stringify(this.config.SYNTHESE.MAP_CRITERIA_LIST));
    }
  }

  private extractNomenclatures() {
    if (this.config.SYNTHESE.MAP_CRITERIA_LIST) {
      let mnemonics = [];
      for (const criteriaCode in this.criteriaConfig) {
        const criteria = this.criteriaConfig[criteriaCode];
        if (criteria['mnemonic']) {
          mnemonics.push(criteria.mnemonic);
        }
      }
      if (mnemonics.length > 0) {
        this.getNomenclatures(mnemonics);
      }
    }
  }

  private getNomenclatures(mnemonics) {
    this.dataFormService
      .getNomenclatures(mnemonics)
      .pipe(
        map((data) => {
          let nomenclatures = {};
          for (let i = 0; i < data.length; i++) {
            nomenclatures[data[i].mnemonique] = [];
            data[i].values.forEach((element) => {
              nomenclatures[data[i].mnemonique][element.id_nomenclature] = element.cd_nomenclature;
            });
          }
          return nomenclatures;
        })
      )
      .subscribe((nomenclatures) => {
        this.nomenclatures = nomenclatures;
      });
  }

  private selectDefaultCriteria() {
    if (this.config.SYNTHESE.MAP_CRITERIA_LIST) {
      for (const criteriaCode in this.criteriaConfig) {
        const criteria = this.criteriaConfig[criteriaCode];
        criteria.code = criteriaCode;
        if (criteria['default'] && criteria.default === true) {
          this.selectedCriteria = criteria;
        }
      }
    }

    if (
      this.config.SYNTHESE.AREA_AGGREGATION_ENABLED &&
      this.config.SYNTHESE.AREA_AGGREGATION_BY_DEFAULT
    ) {
      this.selectedCriteria = {
        code: this.areaAggregationCriteriaCode,
      };
    }
  }

  private initializeQueryParams() {
    this.formService.selectors = this.formService.selectors.set(
      'format',
      this.selectedCriteria.code == this.areaAggregationCriteriaCode
        ? 'grouped_geom_by_areas'
        : 'grouped_geom'
    );

    if (this.selectedCriteria.field) {
      this.formService.selectors = this.formService.selectors.set(
        'with_field',
        this.selectedCriteria.field
      );
    }
  }

  ngOnDestroy() {
    this.destroy$.next(true);
    this.destroy$.unsubscribe();
  }

  isDefaultDisplay() {
    return this.selectedCriteria.code === this.defaultCriteriaCode;
  }

  isAreasAggDisplay() {
    return this.selectedCriteria.code === this.areaAggregationCriteriaCode;
  }

  isCriteriaDisplay() {
    return this.selectedCriteria.hasOwnProperty('field');
  }

  getCurrentField() {
    return this.selectedCriteria.field;
  }

  getCurrentCode() {
    return this.selectedCriteria.code;
  }

  /**
   * Build the "Affichage des observations" title + <select> mode picker that sits
   * at the top of the merged legend control, mirroring the options previously
   * offered by the (now removed) standalone radio-button selector control.
   * @param container The legend control root element to append the title/select to.
   * @param includeCriteriaList Whether to also list the configured MAP_CRITERIA_LIST
   * entries (false when only the area aggregation toggle is available).
   */
  private buildLegendModeSelector(container, includeCriteriaList: boolean) {
    let title = L.DomUtil.create('h6', 'legend-title', container);
    this.translateService
      .stream('Synthese.Map.LegendTitle')
      .pipe(takeUntil(this.destroy$))
      .subscribe((txt) => {
        title.innerText = txt;
      });

    let select = L.DomUtil.create('select', 'criteria-control-select', container);
    L.DomEvent.disableClickPropagation(select);

    // Add default display entry
    let defaultOption = L.DomUtil.create('option', '', select);
    defaultOption.value = this.defaultCriteriaCode;
    if (this.selectedCriteria.code == this.defaultCriteriaCode) {
      defaultOption.selected = true;
    }
    this.translateService
      .stream(`Synthese.Map.Criteria.${this.defaultCriteriaCode}`)
      .pipe(takeUntil(this.destroy$))
      .subscribe((txt) => {
        defaultOption.innerText = txt;
      });

    // Add observations area aggregation display entry
    if (this.config.SYNTHESE.AREA_AGGREGATION_ENABLED) {
      let areaOption = L.DomUtil.create('option', '', select);
      areaOption.value = this.areaAggregationCriteriaCode;
      if (this.selectedCriteria.code == this.areaAggregationCriteriaCode) {
        areaOption.selected = true;
      }
      this.translateService
        .stream(`Synthese.Map.Criteria.${this.areaAggregationCriteriaCode}`)
        .pipe(takeUntil(this.destroy$))
        .subscribe((txt) => {
          areaOption.innerText = txt;
        });
    }

    // Add criteria display list
    if (includeCriteriaList && this.config.SYNTHESE.MAP_CRITERIA_LIST) {
      for (const criteriaCode in this.criteriaConfig) {
        const criteria = this.criteriaConfig[criteriaCode];
        criteria.code = criteriaCode;
        if (criteria.activate === false) {
          // This criterion is disabled in the configuration file
          continue;
        }

        let option = L.DomUtil.create('option', '', select);
        option.value = criteria.code;
        const prefix = this.translateService.instant('Synthese.Map.CriteriaPrefix');
        const label = criteria.label || '';
        const isAcronym =
          label.length > 1 && label === label.toUpperCase() && label !== label.toLowerCase();
        option.innerText = `${prefix} ${isAcronym ? label : label.charAt(0).toLowerCase() + label.slice(1)}`;
        if (criteria.description) {
          option.setAttribute('title', criteria.description);
        }
        if (criteria.code == this.selectedCriteria.code) {
          option.selected = true;
          this.prepareMarkerStyles();
        }
      }
    }

    select.onchange = () => {
      const value = select.value;
      if (value == this.defaultCriteriaCode) {
        this.selectedCriteria = {
          code: this.defaultCriteriaCode,
        };
      } else if (value == this.areaAggregationCriteriaCode) {
        this.selectedCriteria = {
          code: this.areaAggregationCriteriaCode,
        };
      } else if (this.criteriaConfig && this.criteriaConfig[value]) {
        this.selectedCriteria = this.criteriaConfig[value];
      }
      this.activateMapDisplayCriteria();
    };

    return select;
  }

  private activateMapDisplayCriteria() {
    let event: EventDisplayCriteria = {
      type: 'point',
      name: this.selectedCriteria.code,
    };

    this.formService.selectors = this.formService.selectors
      .delete('with_field')
      .set('format', 'grouped_geom');

    if (this.selectedCriteria.code == this.areaAggregationCriteriaCode) {
      event.type = 'grid';
      this.formService.selectors = this.formService.selectors.set(
        'format',
        'grouped_geom_by_areas'
      );
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

    this.onCriteriaActivated.next(event);
  }

  /**
   * The legend control now doubles as the display mode picker (dropdown), so it
   * must always be built (not only once a non-default mode is active) whenever a
   * mode picker is available at all, mirroring the previous buildSelectionControl
   * availability condition.
   */
  buildLegendControl() {
    if (this.config.SYNTHESE.AREA_AGGREGATION_ENABLED || this.config.SYNTHESE.MAP_CRITERIA_LIST) {
      if (this.config.SYNTHESE.MAP_CRITERIA_LIST) {
        return this.buildCriteriaLegend();
      } else {
        return this.buildAreasLegend();
      }
    }
    return null;
  }

  private legendContainerModeClass(): string {
    return this.isAreasAggDisplay() ? 'areas' : 'criteria';
  }

  private buildCriteriaLegend() {
    if (this.isCriteriaDisplay()) {
      this.prepareCriteriaLegend();
    }
    // TODO: return only the add function et create Control.Extend in synthese-carte
    return (map) => {
      let div = L.DomUtil.create('div', `info legend ${this.legendContainerModeClass()}`);
      L.DomEvent.disableClickPropagation(div);
      L.DomEvent.disableScrollPropagation(div);

      this.buildLegendModeSelector(div, true);

      if (this.isAreasAggDisplay()) {
        this.appendAreasLegendContent(div);
      } else if (this.isCriteriaDisplay()) {
        this.appendCriteriaLegendContent(div);
      }

      return div;
    };
  }

  private appendCriteriaLegendContent(container) {
    let content = L.DomUtil.create('div', 'legend-content', container);

    let labels = [];
    // Loop through our criteria prepared legend styles and
    // generate a label with a colored square for each interval
    for (var i = 0; i < this.selectedCriteria.preparedLegendStyles.length; i++) {
      let grade = this.selectedCriteria.preparedLegendStyles[i];
      let colorBlock = this.prepareLegendColorBlock(grade);
      if (grade.description) {
        labels.push(`<span title="${grade.description}">${colorBlock} ${grade.label}</span>`);
      } else {
        labels.push(`${colorBlock} ${grade.label}`);
      }
    }
    content.innerHTML = labels.join('<br>');
  }

  private prepareLegendColorBlock(grade) {
    return `<i class="legend-color" style="${grade.css.join(';')}"></i>`;
  }

  private buildAreasLegend() {
    return (map) => {
      let div = L.DomUtil.create('div', `info legend ${this.legendContainerModeClass()}`);
      L.DomEvent.disableClickPropagation(div);
      L.DomEvent.disableScrollPropagation(div);

      this.buildLegendModeSelector(div, false);

      if (this.isAreasAggDisplay()) {
        this.appendAreasLegendContent(div);
      }

      return div;
    };
  }

  private appendAreasLegendContent(container) {
    const vm = this;
    let content = L.DomUtil.create('div', 'legend-content', container);
    let grades = this.config['SYNTHESE']['AREA_AGGREGATION_LEGEND_CLASSES']
      .map((legendClass) => legendClass.min)
      .reverse();
    let labels = [];

    // Loop through our density intervals and generate a label with
    // a colored square for each interval
    for (var i = 0; i < grades.length; i++) {
      let color = vm.getColor(grades[i] + 1);
      let label = grades[i] + (grades[i + 1] ? ` &ndash; ${grades[i + 1]}` : '+');
      labels.push(`<i class="legend-color" style="background: ${color}"></i> ${label}`);
    }
    content.innerHTML = labels.join('<br>');
  }

  public getColor(obsNbr) {
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
  }

  /**
   * Convert hex color to RGBA value.
   * @see {@link https://stackoverflow.com/a/21648508}
   * @param hex Hexadecimal code.
   * @param opacity Float number to indicate the opacity of the RGBA value.
   * @throws {Error} Bad hex color value.
   * @returns The color value in RGBA format.
   */
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

  private prepareMarkerStyles() {
    this.prepareCriteriaValues();

    let preparedMarkerStyles = {};
    this.selectedCriteria.preparedValues.forEach((item) => {
      let valuesList = Array.isArray(item.value) ? item.value : [item.value];
      valuesList.forEach((val) => {
        preparedMarkerStyles[val] = item;
      });
    });
    this.selectedCriteria.preparedMarkerStyles = preparedMarkerStyles;
  }

  private prepareCriteriaValues() {
    if (this.selectedCriteria.preparedValues) {
      return;
    }

    // Add several values by geom entry
    this.prepareSeveralValuesEntry();

    // Add unknown values by geom entry
    this.prepareUnknownValueEntry();

    // Compute values
    let preparedValues = [];
    this.selectedCriteria.values.forEach((item) => {
      item.value = Array.isArray(item.value) ? item.value : [item.value];
      item.styles = this.prepareStyles(item);
      preparedValues.push(item);
    });

    this.selectedCriteria.preparedValues = preparedValues;
  }

  private prepareSeveralValuesEntry() {
    let severalValuesEntry = this.selectedCriteria.values.find((item) => item.value === '*');
    if (
      severalValuesEntry &&
      (!severalValuesEntry.hasOwnProperty('label') || severalValuesEntry.label == '')
    ) {
      severalValuesEntry.label = this.translateService.instant('Synthese.Map.SeveralValues');
    } else {
      // Raise an error ?
    }
  }

  private prepareUnknownValueEntry() {
    let unknownValueEntry = this.selectedCriteria.values.find((item) => item.value === '?');
    if (
      unknownValueEntry &&
      (!unknownValueEntry.hasOwnProperty('label') || unknownValueEntry.label == '')
    ) {
      unknownValueEntry.label = this.translateService.instant('Synthese.Map.UnknownValue');
    } else {
      // Raise an error ?
    }
  }

  private prepareStyles(criteriaValue) {
    let styles = {
      // Border
      stroke: true,
      weight: 3,
      opacity: 1.0,
      color: criteriaValue.color,
      // Content
      fill: true,
      fillOpacity: 1.0,
      fillColor: criteriaValue.color,
    };
    return styles;
  }

  getOriginStyle(layer) {
    let originStyle = this.getOriginDefaultStyle();
    if (!this.isDefaultDisplay() && !this.isAreasAggDisplay()) {
      // Explicitly reset fill/fillColor/fillOpacity: Leaflet's setStyle merges the
      // given keys onto the existing options, so getSelectedStyle's fillOpacity: 1
      // would otherwise never be cleared when restoring the unselected style.
      const criteriaStyle = this.getCriteriaStyle(layer.feature.properties.observations);
      originStyle = {
        ...criteriaStyle,
        fill: true,
        fillColor: criteriaStyle.color,
        fillOpacity: this.criteriaOriginFillOpacity,
      };
    }
    return originStyle;
  }

  private getOriginDefaultStyle() {
    return this.isAreasAggDisplay() ? this.originAreasStyle : this.originDefaultStyle;
  }

  getSelectedStyle(layer?) {
    if (!this.isDefaultDisplay() && !this.isAreasAggDisplay()) {
      // Criteria mode: don't override the criteria color with red, highlight the
      // selection by fully filling the shape with its own color instead.
      const criteriaStyle = this.getCriteriaStyle(layer.feature.properties.observations);
      return {
        ...criteriaStyle,
        fill: true,
        fillColor: criteriaStyle.color,
        fillOpacity: 1,
      };
    }
    return this.isAreasAggDisplay() ? this.selectedAreasStyle : this.selectedDefaultStyle;
  }

  getCriteriaStyle(observations) {
    let criteriaStyle = null;
    const type = this.selectedCriteria.type;
    const values = this.getObservationsCriteriaValues(observations);

    let distinctCriteriaStyles = new Set();
    for (let value of values) {
      if (type == 'nomenclatures') {
        if (this.selectedCriteria['mnemonic']) {
          value = this.nomenclatures[this.selectedCriteria.mnemonic][value];
        }
        criteriaStyle = this.selectedCriteria.preparedMarkerStyles[value];

        if (criteriaStyle && distinctCriteriaStyles.has(criteriaStyle.color) === false) {
          distinctCriteriaStyles.add(criteriaStyle.color);
        }
      } else if (['classes', 'dates'].includes(type)) {
        const classes: string[] = Object.keys(this.selectedCriteria.preparedMarkerStyles);
        classes.splice(classes.indexOf('*'), 1);
        classes.splice(classes.indexOf('?'), 1);

        let sortedClasses: string[] | number[] = [];
        if (type == 'classes') {
          const numericClasses: number[] = classes.map(Number);
          sortedClasses = numericClasses.sort((a, b) => b - a);
          value = Number(value);
        } else {
          sortedClasses = classes.sort().reverse();
        }

        let classesNbr = sortedClasses.length;
        for (let i = 0; i < classesNbr; i++) {
          let classeValue = sortedClasses[i];
          if (value > classeValue) {
            criteriaStyle = this.selectedCriteria.preparedMarkerStyles[classeValue];
            break;
          }
        }

        if (criteriaStyle && distinctCriteriaStyles.has(criteriaStyle.color) === false) {
          distinctCriteriaStyles.add(criteriaStyle.color);
        }
      }
    }

    // Set multiple values criteria style if necessary
    if (distinctCriteriaStyles.size > 1) {
      criteriaStyle = this.selectedCriteria.preparedMarkerStyles['*'];
    }

    // Set unknown value criteria style if necessary
    if (!criteriaStyle) {
      criteriaStyle = this.selectedCriteria.preparedMarkerStyles['?'];
    }

    return criteriaStyle;
  }

  private getObservationsCriteriaValues(observations) {
    const field = this.getCurrentField();
    let values = [];
    if (Array.isArray(observations)) {
      // Raw API shape (used e.g. by the taxon/observer sheets' map): an array
      // of individual observation objects, each possibly holding the field as
      // a scalar or array value, instead of the single object with array-typed
      // fields built by SyntheseComponent.parseGeoJson() for the main map.
      observations.forEach((obs) => {
        if (obs[field] === undefined || obs[field] === null) {
          return;
        }
        values.push(...(Array.isArray(obs[field]) ? obs[field] : [obs[field]]));
      });
    } else if (observations[field]) {
      values = Array.isArray(observations[field]) ? observations[field] : [observations[field]];
    }
    return values;
  }

  buildCriteriaTxt(criteria) {
    let txt = '';
    if (criteria['label'] && criteria.label != '') {
      txt = criteria.label;
    }
    if (criteria['description'] && criteria.description != '') {
      let description = criteria.description;
      if (txt == '') {
        txt = description;
      } else {
        description = description.charAt(0).toLowerCase() + description.slice(1);
        txt += ` : ${description}`;
      }
    }
    return txt;
  }
}
