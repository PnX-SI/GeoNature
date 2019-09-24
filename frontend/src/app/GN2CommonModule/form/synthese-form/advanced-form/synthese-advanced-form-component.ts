import { Component, OnInit, ViewChild, AfterContentInit } from '@angular/core';
import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';
import { TreeNode, TreeComponent, IActionMapping } from 'angular-tree-component';
import { SyntheseFormService } from '@geonature_common/form/synthese-form/synthese-form.service';
import { DynamicFormService } from '@geonature_common/form/dynamic-form-generator/dynamic-form.service';
import { FormGroup } from '@angular/forms';
import { TaxonAdvancedStoreService } from '@geonature_common/form/synthese-form/advanced-form/synthese-advanced-form-store.service';
import { AppConfig } from '@geonature_config/app.config';

@Component({
  selector: 'pnx-validation-taxon-advanced',
  templateUrl: './synthese-advanced-form.component.html',
  providers: [DynamicFormService],
  styleUrls: ['./synthese-advanced-form.component.scss']
})
export class TaxonAdvancedModalComponent implements OnInit, AfterContentInit {
  @ViewChild('tree') treeComponent: TreeComponent;
  public AppConfig = AppConfig;
  public URL_AUTOCOMPLETE = AppConfig.API_TAXHUB + '/taxref/search/lb_nom';
  public taxonsTree;
  public treeOptions;
  public selectedNodes = [];
  public expandedNodes = [];
  public taxhubAttributes: any;
  public attributForm: FormGroup;
  public formBuilded = false;
  public queryString = { add_rank: true, rank_limit: 'GN' };
  public showTree = false;

  constructor(
    public activeModal: NgbActiveModal,
    public formService: SyntheseFormService,
    public storeService: TaxonAdvancedStoreService
  ) {
    const actionMapping: IActionMapping = {
      mouse: {
        click: (tree, node, $event) => {},
        checkboxClick: (tree, node, $event) => {
          node.toggleSelected();
          if (!node.isExpanded) {
            node.toggleExpanded();
          }
          //this.expandNodeRecursively(node, 0);
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

  mapFunc(item) {
    item['displayed_name'] = '<b>' + item.lb_nom + ' </b>  <small> (' + item.nom_rang + ')</small>';
    return item;
  }

  toggleTree() {
    this.showTree = !this.showTree;
  }

  // Algo pour 'expand' tous les noeud fils recursivement à partir un noeud parent
  // depth : profondeur de l'arbre jusqu'ou on ouvre
  // Non utilisée pour des raisons de performances
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

  onTaxonSelected($event) {
    this.formService.selectedTaxonFromRankInput.push($event.item);
    $event.preventDefault();
    this.formService.searchForm.controls.taxon_rank.reset();
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

  formatter(item) {
    return item.lb_nom;
  }
}
