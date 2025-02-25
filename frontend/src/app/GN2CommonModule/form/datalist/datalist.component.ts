import { Component, OnInit, Input } from '@angular/core';
import { DataFormService } from '../data-form.service';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';
import { CommonService } from '../../service/common.service';

@Component({
  selector: 'pnx-datalist',
  templateUrl: './datalist.component.html',
})
export class DatalistComponent extends GenericFormComponent implements OnInit {
  formId: string; // Unique form id

  @Input() designStyle: 'bootstrap' | 'material' = 'material';
  @Input() values: Array<any>; // list of choices
  @Input() keyLabel = 'label'; // field name for value
  @Input() keyValue = 'value'; // field name for label
  @Input() keyTitle; // field name for description (title in select option)

  @Input() api: string; // api from 'GeoNature', 'TaxHub' or url to foreign app
  @Input() application: string; // 'GeoNature', 'TaxHub' for api's; null for raw url
  @Input() params: any = {}; // parametres get pour la requete { orderby: truc } => api?orderby=truc
  @Input() data: any = undefined;

  @Input() multiple: boolean;
  @Input() required: boolean;
  @Input() definition: boolean; // help

  @Input() filters = {}; // help

  @Input() default;
  @Input() nullDefault;

  @Input() dataPath: string; // pour atteindre la liste si elle n'est pas à la racine de la réponse de l'api.
  // si on a 'data/liste' on mettra dataPath='data'

  search = '';
  filteredValues;

  constructor(
    private _dfs: DataFormService,
    private _commonService: CommonService
  ) {
    super();
  }

  ngOnInit() {
    super.ngOnInit();
    this.designStyle = this.designStyle || 'material';
    this.formId = `datalist_${Math.ceil(Math.random() * 1e10)}`;
    this.getData();
  }

  onToppingRemoved(val) {
    const value = this.parentFormControl.value;
    this.parentFormControl.patchValue(value.filter((v) => v !== val));
  }

  searchChanged(event) {
    this.search = event;
    this.filteredValues = this.getFilteredValues();
  }

  getFilteredValues() {
    let values = this.values || [];
    // if(this.nullDefault){
    //   values.push()
    // }
    if (this.nullDefault && !this.required) {
      let obj = {};
      obj[this.keyValue] = null;
      obj[this.keyLabel] = '-- Aucun --';
      values.unshift(obj);
    }
    values = values
      // filter search
      .filter(
        (v) =>
          !this.search || this.displayLabel(v).toLowerCase().includes(this.search.toLowerCase())
      )
      // remove doublons (keyValue)
      .filter(
        (item, pos, self) => self.findIndex((i) => i[this.keyValue] === item[this.keyValue]) === pos
      );

    for (const key of Object.keys(this.filters || [])) {
      const filter_ = this.filters[key];
      if (filter_.length) {
        values = filter_.map((f) => values.find((v) => v[key] === f)).filter((v) => !!v);
      }
    }

    return values;
  }

  selectedValues() {
    return this.parentFormControl.value
      ? this.multiple
        ? this.parentFormControl.value
        : [this.parentFormControl.value]
      : [];
  }

  displayLabel(value) {
    let label = '';
    for (const key of this.keyLabel.split(',')) {
      label = label || value[key.trim()];
    }
    return label;
  }

  displayLabelFromValue(value) {
    if (!value) {
      return '';
    }
    const label = '';
    const item = (this.values || []).find((v) => v[this.keyValue] === value);
    if (item) {
      return this.displayLabel(item);
    }
    return undefined;
  }

  initValues(data) {
    this.values = data ? data.map((v) => (typeof v !== 'object' ? { label: v, value: v } : v)) : [];
    this.filteredValues = this.getFilteredValues();
    // si requis
    // et un seul choix
    // et pas de valeur déjà choisie
    // alors on assigne ce choix d'office

    if (
      this.required &&
      this.filteredValues.length === 1 &&
      !(this.parentFormControl.value && this.parentFormControl.value.length)
    ) {
      const val = this.nullDefault ? null : this.values[0][this.keyValue];
      this.parentFormControl.patchValue(this.multiple && !this.nullDefault ? [val] : val);
    }

    // valeur par défaut (depuis input value)
    if (
      (!this.parentFormControl.value ||
        (Array.isArray(this.parentFormControl.value) &&
          this.parentFormControl.value.length == 0)) &&
      this.default
    ) {
      const value = this.multiple ? this.default : [this.default];
      // check if the default value is in the provided values
      const valuesID = this.values.map((el) => el[this.keyValue]);
      const defaultValuesID = value.map((el) => el[this.keyValue]);
      const defaultValueIsInValues = valuesID.some((el) => defaultValuesID.includes(el));

      // patch value only if default value is in values
      if (defaultValueIsInValues) {
        const res = value.map((val) =>
          typeof val === 'object'
            ? (this.filteredValues.find((v) =>
                Object.keys(val).every((key) => v[key] === val[key])
              ) || {})[this.keyValue]
            : val
        );
        this.parentFormControl.patchValue(this.multiple ? res : res[0]);
      }
    }
    this.parentFormControl.markAsTouched();
  }

  getData() {
    if (!this.values && this.api) {
      this._dfs
        .getDataList(this.api, this.application, this.params, this.data)
        .subscribe((data) => {
          let values = data;
          if (this.dataPath) {
            const paths = this.dataPath.split('/');
            for (const path of paths) {
              values = values[path];
            }
          }
          this.initValues(values);
        });
    } else if (this.values) {
      this.initValues(this.values);
    }
  }
}
