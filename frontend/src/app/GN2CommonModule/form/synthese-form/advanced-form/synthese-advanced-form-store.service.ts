import { Injectable } from '@angular/core';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { SyntheseFormService } from '@geonature_common/form/synthese-form/synthese-form.service';
import { DynamicFormService } from '@geonature_common/form/dynamic-form/dynamic-form.service';
import { TreeModel } from 'angular-tree-component';
import { AppConfig } from '@geonature_config/app.config';
import { formatTaxonTree } from '@geonature_common/form/taxon-tree/taxon-tree.service';

@Injectable()
export class TaxonAdvancedStoreService {
  public AppConfig = AppConfig;
  public taxonTree: any;
  public treeModel: TreeModel;
  public taxonTreeState: any;
  public taxhubAttributes: any;
  public formBuilded: boolean;
  public taxonomyLR: Array<any>;
  public taxonomyHab: Array<any>;
  public taxonomyGroup2Inpn: Array<any>;

  constructor(
    private _dataService: DataFormService,
    private _validationDataService: SyntheseDataService,
    private _formService: SyntheseFormService,
    private _formGen: DynamicFormService
  ) {
    if (AppConfig.SYNTHESE.DISPLAY_TAXON_TREE) {
      this._validationDataService.getTaxonTree().subscribe(data => {
        this.taxonTree = formatTaxonTree(data);
      });
    }

    // get taxhub attributes
    this._dataService.getTaxhubBibAttributes().subscribe(attrs => {
      // display only the taxhub attributes set in the config
      this.taxhubAttributes = attrs
        .filter(attr => {
          return AppConfig.SYNTHESE.ID_ATTRIBUT_TAXHUB.indexOf(attr.id_attribut) !== -1;
        })
        .map(attr => {
          // format attributes to fit with the GeoNature dynamicFormComponent
          attr['values'] = JSON.parse(attr['liste_valeur_attribut']).values;
          attr['attribut_name'] = 'taxhub_attribut_' + attr['id_attribut'];
          attr['required'] = attr['obligatoire'];
          attr['attribut_label'] = attr['label_attribut'];
          if (attr['type_widget'] == 'multiselect') {
            attr['values'] = attr['values'].map(val => {
              return { value: val };
            });
          }
          this._formGen.addNewControl(attr, this._formService.searchForm);

          return attr;
        });
      this.formBuilded = true;
    });
    // load LR,  habitat and group2inpn
    this._dataService.getTaxonomyLR().subscribe(data => {
      this.taxonomyLR = data;
    });

    this._dataService.getTaxonomyHabitat().subscribe(data => {
      this.taxonomyHab = data;
    });

    const all_groups = [];
    this._dataService.getRegneAndGroup2Inpn().subscribe(data => {
      this.taxonomyGroup2Inpn = data;
      // tslint:disable-next-line:forin
      for (let regne in data) {
        data[regne].forEach(group => {
          if (group.length > 0) {
            all_groups.push({ value: group });
          }
        });
      }
      this.taxonomyGroup2Inpn = all_groups;
    });
  }
}
