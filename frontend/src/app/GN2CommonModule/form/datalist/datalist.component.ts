import {
  Component,
  OnInit,
  Input,
  OnChanges,
  DoCheck,
  IterableDiffers,
  IterableDiffer
} from '@angular/core';
import { DataFormService } from '../data-form.service';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';
import { CommonService } from '../../service/common.service';

@Component({
  selector: 'pnx-datalist',
  templateUrl: './datalist.component.html'
})
export class DatalistComponent extends GenericFormComponent implements OnInit {

  formId: string; // Unique form id

  @Input() values: Array<any>; // list of choices
  @Input() keyLabel = 'label'; // field name for value
  @Input() keyValue = 'value'; // field name for label

  @Input() api: string; // api from 'GeoNature', 'TaxHub' or url to foreign app
  @Input() application: string; // 'GeoNature', 'TaxHub' for api's; null for raw url
  @Input() params: boolean; // parametres get pour la requete { orderby: truc } => api?orderby=truc

  @Input() multiple: boolean;
  @Input() required: boolean;

  @Input() dataPath: string; // pour atteindre la liste si elle n'est pas à la racine de la réponse de l'api.
  // si on a 'data/liste' on mettra dataPath='data'

  search = '';
  filteredValues;

  constructor(
    private _dfs: DataFormService,
    private _commonService: CommonService,
  ) {
    super();
  }

  ngOnInit() {
    this.formId = `datalist_${Math.ceil(Math.random() * 1e10)}`;
    this.getData();
  }

  onToppingRemoved(val) {

    const value = this.parentFormControl.value;
    this.parentFormControl.patchValue(value.filter(v => v !== val));
  }

  searchChanged(event) {
    console.log('search changed');
    this.filteredValues = this.getFilteredValues();
  }

  getFilteredValues() {
    return (this.values || []).filter(v => !this.search || this.displayLabel(v).includes(this.search));
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
    const item = (this.values || []).find(v => v[this.keyValue] === value);
    return this.displayLabel(item);
  }


  initValues(data) {
    this.values = data.map(v => typeof v !== 'object' ? { label: v, value: v } : v);
    this.filteredValues = this.getFilteredValues();

    // si requis
    // et un seul choix
    // et pas de valeur déjà choisie
    // alors on assigne ce choix d'office
    if (this.required && this.values.length === 1 && !(this.parentFormControl.value && this.parentFormControl.value.length)) {
      const val = this.values[0][this.keyValue];
      this.parentFormControl.patchValue(this.multiple ? [val] : val);
    }
  }

  getData() {
    if (!this.values && this.api) {
      this._dfs.getDataList(this.api, this.application, this.params)
        .subscribe(
          (data) => {
            let values = data;
            if (this.dataPath) {
              const paths = this.dataPath.split('/');
              for (const path of paths) {
                values = values[path];
              }
            }
            this.initValues(values);
          },
          (error) => {
            console.log('error', error);
            this._commonService.regularToaster('error', error);
          }
        );
    } else if (this.values) {
      this.initValues(this.values);
    }
  }


}
