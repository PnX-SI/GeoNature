import { Injectable } from '@angular/core';

import { DataFormService } from '@geonature_common/form/data-form.service';

import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { SyntheseFormService } from '@geonature_common/form/synthese-form/synthese-form.service';
import { DynamicFormService } from '@geonature_common/form/dynamic-form-generator/dynamic-form.service';
import { TreeModel } from '@circlon/angular-tree-component';
import { formatTaxonTree } from '@geonature_common/form/taxon-tree/taxon-tree.service';
import { ConfigService } from '@geonature/services/config.service';

@Injectable()
export class TaxonAdvancedStoreService {
  public displayTaxonTree: Boolean = false;
  public taxonTree: any;
  public treeModel: TreeModel;
  public taxonTreeState: any;
  public taxhubAttributes: any;
  public formBuilded: boolean;
  public taxonomyHab: Array<any>;
  public taxonomyGroup2Inpn: Array<any>;
  public redListsValues: any = {};

  constructor(
    private _dataService: DataFormService,
    private _validationDataService: SyntheseDataService,
    private _formService: SyntheseFormService,
    private _formGen: DynamicFormService,
    public config: ConfigService
  ) {
    // Set taxon tree if needed
    if (this.config.SYNTHESE.DISPLAY_TAXON_TREE) {
      this.displayTaxonTree = true;
      this._validationDataService.getTaxonTree().subscribe((data) => {
        this.taxonTree = formatTaxonTree(data);
      });
    }

    // Set protection status filters data
    this._formService.statusFilters.forEach((status) => {
      this._dataService.getStatusType(status.status_types).subscribe((data) => {
        status.values = data;
      });
    });

    // Set red lists filters data
    this._formService.redListsFilters.forEach((redList) => {
      this._dataService.getStatusValues(redList.status_type).subscribe((data) => {
        redList.values = data;
      });
    });

    // Get TaxHub attributes
    this._dataService.getTaxhubBibAttributes().subscribe((attrs) => {
      // Display only the taxhub attributes set in the config
      this.taxhubAttributes = attrs
        .filter((attr) => {
          return this.config.SYNTHESE.ID_ATTRIBUT_TAXHUB.indexOf(attr.id_attribut) !== -1;
        })
        .map((attr) => {
          // Format attributes to fit with the GeoNature dynamicFormComponent
          attr['values'] = JSON.parse(attr['liste_valeur_attribut']).values;
          attr['attribut_name'] = 'taxhub_attribut_' + attr['id_attribut'];
          attr['required'] = attr['obligatoire'];
          attr['attribut_label'] = attr['label_attribut'];
          if (attr['type_widget'] == 'multiselect') {
            attr['values'] = attr['values'].map((val) => {
              return { value: val };
            });
          }
          this._formGen.addNewControl(attr, this._formService.searchForm);

          return attr;
        });
      this.formBuilded = true;
    });

    // Load habitat and group2inpn
    this._dataService.getTaxonomyHabitat().subscribe((data) => {
      this.taxonomyHab = data;
    });

    const all_groups = [];
    this._dataService.getRegneAndGroup2Inpn().subscribe((data) => {
      this.taxonomyGroup2Inpn = data;
      // eslint-disable-next-line guard-for-in
      for (let regne in data) {
        data[regne].forEach((group) => {
          if (group.length > 0) {
            all_groups.push({ value: group });
          }
        });
      }
      this.taxonomyGroup2Inpn = all_groups;
    });
  }
}
