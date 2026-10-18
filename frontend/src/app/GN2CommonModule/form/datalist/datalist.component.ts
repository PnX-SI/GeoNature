import { Component, OnInit, Input } from '@angular/core';
import { DataFormService } from '../data-form.service';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';
import { extractByPath, normalizeValues } from './datalist.utils';

/**
 * Datalist connected to the API (the display part is in ``pnx-datalist-select``)
 */
@Component({
  selector: 'pnx-datalist',
  templateUrl: './datalist.component.html',
})
export class DatalistComponent extends GenericFormComponent implements OnInit {
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
  @Input() orderBy: 'asc' | 'desc';

  @Input() default;
  @Input() nullDefault;

  @Input() dataPath: string; // pour atteindre la liste si elle n'est pas à la racine de la réponse de l'api.
  // si on a 'data/liste' on mettra dataPath='data'

  /** Values given to ``pnx-datalist-select``: the ``values`` input or the ones fetched from ``api`` */
  resolvedValues: Array<any>;

  constructor(private _dfs: DataFormService) {
    super();
  }

  ngOnInit() {
    super.ngOnInit();
    this.designStyle = this.designStyle || 'material';
    this.getData();
  }

  getData() {
    if (!this.values && this.api) {
      this._dfs
        .getDataList(this.api, this.application, this.params, this.data)
        .subscribe((data) => {
          this.resolvedValues = normalizeValues(extractByPath(data, this.dataPath));
        });
    } else if (this.values) {
      this.resolvedValues = normalizeValues(this.values);
    }
  }
}
