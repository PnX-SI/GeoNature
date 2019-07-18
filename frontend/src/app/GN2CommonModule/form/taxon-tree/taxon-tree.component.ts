import {
  Component,
  OnInit,
  Input,
  Output,
  EventEmitter,
  AfterContentInit,
  ViewChild
} from '@angular/core';
import { TreeModel } from 'angular-tree-component';
import { TreeNode, TreeComponent, IActionMapping } from 'angular-tree-component';

/** Generic component for display taxon tree. Not use yet */
@Component({
  selector: 'pnx-tree',
  templateUrl: 'taxon-tree.component.html'
})
export class TaxonTreeComponent implements OnInit, AfterContentInit {
  public selectedNodes = [];
  public expandedNodes = [];
  public selectedCdRefFromTree = [];

  @Input() taxonTreeState: any;
  @Input() taxonTree: any;
  @Input() treeModel: TreeModel;
  @Input() treeOptions;
  @Output() onReset = new EventEmitter<any>();
  @Output() onEvent = new EventEmitter<any>();
  @ViewChild('tree') treeComponent: TreeComponent;

  constructor() {
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
    if (this.taxonTreeState) {
      this.treeModel.setState(this.taxonTreeState);
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
    this.treeModel = this.treeComponent.treeModel;
  }

  catchEvent(event) {
    if (event.eventName === 'select') {
      // push the cd_nom in taxonList
      this.selectedCdRefFromTree.push(event.node.data.id);
    }
    if (event.eventName === 'deselect') {
      // remove cd_nom from taxonlist
      this.selectedCdRefFromTree.splice(this.selectedCdRefFromTree.indexOf(event.node.data.id), 1);
    }
  }

  resetTree() {
    this.treeModel.collapseAll();
    this.treeModel.doForAll(node => {
      node.setIsSelected(false);
    });
    this.selectedCdRefFromTree = [];
  }
}
