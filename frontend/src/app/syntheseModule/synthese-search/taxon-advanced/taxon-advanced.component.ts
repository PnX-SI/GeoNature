import { Component, OnInit, ViewChild, AfterContentInit } from '@angular/core';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';

import { TreeModel, TreeNode, TreeComponent, IActionMapping } from 'angular-tree-component';
import { SyntheseFormService } from '../../services/form.service';
import { DynamicFormService } from '@geonature_common/form/dynamic-form/dynamic-form.service';
import { FormGroup } from '@angular/forms';
import { TaxonAdvancedStoreService } from './taxon-advanced-store.service';

@Component({
  selector: 'pnx-taxon-tree',
  templateUrl: './taxon-advanced.component.html',
  providers: [DynamicFormService]
})
export class TaxonAdvancedModalComponent implements OnInit, AfterContentInit {
  @ViewChild('tree') treeComponent: TreeComponent;
  public taxonsTree;
  public treeOptions;
  public selectedNodes = [];
  public expandedNodes = [];
  public taxhubAttributes: any;
  public attributForm: FormGroup;
  public formBuilded = false;
  constructor(
    public activeModal: NgbActiveModal,
    public formService: SyntheseFormService,
    public storeService: TaxonAdvancedStoreService
  ) {
    const actionMapping: IActionMapping = {
      mouse: {
        click: (tree, node, $event) => {
          console.log('node', node);
        },
        checkboxClick: (tree, node, $event) => {
          node.toggleSelected();
          if (!node.isExpanded) {
            node.toggleExpanded();
          }
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
    // if the modal has already been open, reload the former state of the taxon tree
    if (this.storeService.taxonTreeState) {
      this.storeService.treeModel.setState(this.storeService.taxonTreeState);
    }
  }

  // Algo pour 'expand' tous les noeud fils recursivement à partir un noeud parent
  expandNodeRecursively(node: TreeNode): void {
    if (node.children) {
      node.children.forEach(subNode => {
        if (!subNode.isExpanded) {
          subNode.toggleExpanded();
        }
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
    console.log('treeeeeeee model');
    this.storeService.treeModel = this.treeComponent.treeModel;
    console.log(this.storeService.treeModel);
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
    this.storeService.taxonTreeState = this.storeService.treeModel.getState();
    console.log('close modal', this.storeService.taxonTreeState);
    this.activeModal.close();
  }
}
