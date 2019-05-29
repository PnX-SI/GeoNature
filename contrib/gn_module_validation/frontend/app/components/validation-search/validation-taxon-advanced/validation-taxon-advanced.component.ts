import { Component, OnInit, ViewChild, AfterContentInit } from '@angular/core';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';
import { ModuleConfig } from '../../../module.config';
import { TreeNode, TreeComponent, IActionMapping } from 'angular-tree-component';
import { FormService } from '../../../services/form.service';
import { DynamicFormService } from '@geonature_common/form/dynamic-form/dynamic-form.service';
import { FormGroup } from '@angular/forms';
import { ValidationTaxonAdvancedStoreService } from './validation-taxon-advanced-store.service';
//import { AppConfig } from '@geonature_config/app.config';

@Component({
  selector: 'pnx-validation-taxon-advanced',
  templateUrl: './validation-taxon-advanced.component.html',
  providers: [DynamicFormService],
  styleUrls: ['./validation-taxon-advanced.component.scss']
})

export class ValidationTaxonAdvancedModalComponent implements OnInit, AfterContentInit {

  @ViewChild('tree') treeComponent: TreeComponent;

  public VALIDATION_CONFIG = ModuleConfig;
  public taxonsTree;
  public treeOptions;
  public selectedNodes = [];
  public expandedNodes = [];
  public taxhubAttributes: any;
  public attributForm: FormGroup;
  public formBuilded = false;

  constructor(
    public activeModal: NgbActiveModal,
    public formService: FormService,
    public storeService: ValidationTaxonAdvancedStoreService
  ) {
    const actionMapping: IActionMapping = {
      mouse: {
        click: (tree, node, $event) => {},
        checkboxClick: (tree, node, $event) => {
          node.toggleSelected();
          if (!node.isExpanded) {
            node.toggleExpanded();
          }
          this.expandNodeRecursively(node, 5);
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
  // depth : profondeur de l'arbre jusqu'ou on ouvre
  expandNodeRecursively(node: TreeNode, depth: number): void {
    depth = depth - 1;
    if (node.children) {
      node.children.forEach(subNode => {
        if (!subNode.isExpanded) {
          subNode.toggleExpanded();
        }
        if (depth > 0) {
          this.expandNodeRecursively(subNode, depth);
        }
      });
    }
  }

  // algo recursif pour retrouver tout les cd_ref sélectionné à partir de l'arbre
  searchSelectedId(node, depth): Array<any> {
    if (node.children) {
      node.children.forEach(subNode => {
        depth = depth - 1;
        if (depth > 0) {
          this.searchSelectedId(subNode, depth);
        }
      });
    } else {
      this.selectedNodes.push(node);
    }
    return this.selectedNodes;
  }

  ngAfterContentInit() {
    this.storeService.treeModel = this.treeComponent.treeModel;
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

  resetTree() {
    this.storeService.treeModel.collapseAll();
    this.storeService.treeModel.doForAll(node => {
      node.setIsSelected(false);
    });
    this.formService.selectedCdRefFromTree = [];
  }

  onCloseModal() {
    this.storeService.taxonTreeState = this.storeService.treeModel.getState();
    this.activeModal.close();
  }
}
