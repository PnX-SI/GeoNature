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
  public taxhubAttributes: Array<any> = [];
  public taxonomyHab: Array<any> = [];
  public taxonomyGroup2Inpn: Array<any> = [];
  public taxonomyGroup3Inpn: Array<any> = [];
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

    this.loadTaxhubAttributes();

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

    this._dataService.getGroup3Inpn().subscribe((data) => {
      this.taxonomyGroup3Inpn = data.map((item) => ({ value: item }));
    });
  }

  private loadTaxhubAttributes(): void {
    const configuredFilterIds =
      this.config.SYNTHESE.ID_ATTRIBUT_TAXHUB_FILTERS ??
      this.config.SYNTHESE.ID_ATTRIBUT_TAXHUB ??
      [];

    if (configuredFilterIds.length === 0) {
      return;
    }

    this._dataService.getTaxhubBibAttributes().subscribe({
      next: (attributes) => {
        this.taxhubAttributes = attributes.reduce((formDefinitions: Array<any>, attribute) => {
          if (!configuredFilterIds.includes(attribute.id_attribut)) {
            return formDefinitions;
          }

          const formDefinition = this.buildTaxhubFilter(attribute);
          if (formDefinition) {
            this._formGen.addNewControl(formDefinition, this._formService.searchForm);
            formDefinitions.push(formDefinition);
          }
          return formDefinitions;
        }, []);
      },
      error: (error) => {
        console.error('Unable to load TaxHub attributes used as filters', error);
        this.taxhubAttributes = [];
      },
    });
  }

  private buildTaxhubFilter(attribute: any): any | null {
    if (!attribute.liste_valeur_attribut) {
      console.warn(
        `TaxHub attribute ${attribute.id_attribut} cannot be used as an advanced filter: ` +
          'liste_valeur_attribut is empty.'
      );
      return null;
    }

    try {
      const definition = JSON.parse(attribute.liste_valeur_attribut);
      if (!Array.isArray(definition?.values)) {
        console.warn(
          `TaxHub attribute ${attribute.id_attribut} cannot be used as an advanced filter: ` +
            'liste_valeur_attribut does not contain a values array.'
        );
        return null;
      }

      return {
        ...attribute,
        values: definition.values,
        attribut_name: `taxhub_attribut_${attribute.id_attribut}`,
        required: attribute.obligatoire,
        attribut_label: attribute.label_attribut,
      };
    } catch (error) {
      console.warn(
        `TaxHub attribute ${attribute.id_attribut} cannot be used as an advanced filter: ` +
          'liste_valeur_attribut is not valid JSON.',
        error
      );
      return null;
    }
  }
}
