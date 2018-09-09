import { Component, OnInit, ViewChild, AfterContentInit } from '@angular/core';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';

import { DataService } from '../../services/data.service';
import {
  TreeModel,
  TreeNode,
  TreeComponent,
  IActionMapping,
  TREE_ACTIONS
} from 'angular-tree-component';
import { SyntheseFormService } from '../../services/form.service';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { DynamicFormService } from '@geonature_common/form/dynamic-form/dynamic-form.service';
import { FormGroup } from '@angular/forms';
import { AppConfig } from '@geonature_config/app.config';
import { FormControl } from '@angular/forms/src/model';

@Component({
  selector: 'pnx-taxon-tree',
  templateUrl: './taxon-advanced.component.html',
  providers: [DynamicFormService]
})
export class TaxonAdvancedModalComponent implements OnInit, AfterContentInit {
  @ViewChild('tree') treeComponent: TreeComponent;
  public taxonsTree;
  public treeOptions;
  public treeModel: TreeModel;
  public selectedNodes = [];
  public expandedNodes = [];
  public taxhubAttributes: any;
  public attributForm: FormGroup;
  public formBuilded = false;
  constructor(
    public activeModal: NgbActiveModal,
    private _dataService: DataService,
    public formService: SyntheseFormService,
    private _dfs: DataFormService,
    private _formGen: DynamicFormService,
  ) {
    const actionMapping: IActionMapping = {
      mouse: {
        click: (tree, node, $event) => {
          console.log('node', node);
        },
        checkboxClick: (tree, node, $event) => {
          node.toggleSelected();
          node.toggleExpanded();
          this.expandNodeRecursively(node);
        }
      }
    };
    this.treeOptions = {
      actionMapping,
      useCheckbox: true
    };
  }

  ngOnInit() {
    // get taxon tree
    if (!this.formService.taxonTree) {
      this._dataService.getTaxonTree().subscribe(data => {
        this.formService.taxonTree = this._dataService.formatTaxonTree(data);
        // if the modal has already been open, reload the former state of the taxon tree
        if (this.formService.taxonTreeState) {
          this.treeModel.setState(this.formService.taxonTreeState);
        }
      });
    }

    // get taxhub attributes
    this._dfs.getTaxhubBibAttributes().subscribe(attrs => {
      // display only the taxhub attributes set in the config
      this.taxhubAttributes = attrs.filter(attr => {
        return AppConfig.SYNTHESE.ID_THEME_ATTRIBUT_TAXHUB.indexOf(attr.id_theme) !== -1;
      }).map(attr => {
        // format attributes to fit with the GeoNature dynamicFormComponent
        attr['values'] = JSON.parse(attr['liste_valeur_attribut']).values;
        attr['attribut_name'] = 'taxhub_attribut_' + attr['id_attribut'];
        attr['required'] = attr['obligatoire'];
        attr['attribut_label'] = attr['label_attribut'];
        if (attr['type_widget'] == 'multiselect') {
          attr['values'] = attr['values'].map(val => {
            return { 'value': val };
          });
        }
        this._formGen.addNewControl(attr, this.formService.searchForm);

        return attr;
      });
      this.formBuilded = true;
      console.log(this.formService.searchForm)
    });
    // load LR,  habitat and group2inpn
    this._dfs.getTaxonomyLR().subscribe(data => {
      this.formService.taxonomyLR = data;
    });

    this._dfs.getTaxonomyHabitat().subscribe(data => {
      this.formService.taxonomyHab = data;
    });

    const all_groups = [];
    this._dfs.getRegneAndGroup2Inpn().subscribe(data => {
      this.formService.taxonomyGroup2Inpn = data;
      console.log(data);
      // tslint:disable-next-line:forin
      for (let regne in data) {
        data[regne].forEach(group => {
          if (group.length > 0) {
            all_groups.push({ 'value': group });
          }
        });
      }
      this.formService.taxonomyGroup2Inpn = all_groups;

    });
  }

  // Algo recursif pour 'expand' tous les noeud fils recursivement à partir un noeud parent
  expandNodeRecursively(node: TreeNode): void {
    if (node.children) {
      node.children.forEach(subNode => {
        console.log(subNode);
        subNode.toggleExpanded();
        this.expandNodeRecursively(subNode);
      });
    }
  }

  // algo recursif pour retrouver tout les cd_ref sélectionné à partir de l'arbre
  searchSelectedId(node): Array<any> {
    if (node.children) {
      node.children.forEach(subNode => {
        this.searchSelectedId(subNode);
      });
    } else {
      this.selectedNodes.push(node);
    }
    return this.selectedNodes;
  }



  ngAfterContentInit() {
    this.treeModel = this.treeComponent.treeModel;
  }

  catchEvent(event) {
    if (event.eventName === 'select') {
      // push the cd_nom in taxonList
      this.formService.selectedCdRefFromTree.push(event.node.data.id);
    }
    if (event.eventName === 'deselect') {
      // remove cd_nom from taxonlist
      this.formService.selectedCdRefFromTree.splice(
        this.formService.selectedCdRefFromTree.indexOf(event.node.data.id),
        1
      );
    }
  }

  onCloseModal() {
    this.formService.taxonTreeState = this.treeModel.getState();
    console.log('close modal', this.formService.taxonTreeState);
    this.activeModal.close();
  }
}
