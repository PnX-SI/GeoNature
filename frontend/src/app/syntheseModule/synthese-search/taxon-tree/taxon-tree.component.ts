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

@Component({
  selector: 'pnx-taxon-tree',
  templateUrl: './taxon-tree.component.html',
  providers: []
})
export class TaxonTreeModalComponent implements OnInit, AfterContentInit {
  @ViewChild('tree') treeComponent: TreeComponent;
  public taxonsTree;
  public treeOptions;
  public treeModel: TreeModel;
  public selectedNodes = [];
  public expandedNodes = [];
  constructor(
    public activeModal: NgbActiveModal,
    private _dataService: DataService,
    public formService: SyntheseFormService
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

  ngOnInit() {
    if (!this.formService.taxonTree) {
      this._dataService.getTaxonTree().subscribe(data => {
        this.formService.taxonTree = this._dataService.formatTaxonTree(data);
        // if the modal has already been open, reload the former state of the taxon tree
        if (this.formService.taxonTreeState) {
          this.treeModel.setState(this.formService.taxonTreeState);
        }
      });
    }
  }

  ngAfterContentInit() {
    this.treeModel = this.treeComponent.treeModel;
  }

  catchEvent(event) {
    if (event.eventName === 'select') {
      // push the cd_nom in taxonList
      this.formService.selectedCdNomFromTree.push(event.node.data.id);
    }
    if (event.eventName === 'deselect') {
      // remove cd_nom from taxonlist
      this.formService.selectedCdNomFromTree.splice(
        this.formService.selectedCdNomFromTree.indexOf(event.node.data.id),
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
