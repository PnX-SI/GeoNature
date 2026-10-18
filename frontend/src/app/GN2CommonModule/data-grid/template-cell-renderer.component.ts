import { Component, TemplateRef } from '@angular/core';
import { ICellRendererAngularComp } from 'ag-grid-angular';
import { ICellRendererParams } from 'ag-grid-community';
import { CellContext } from './data-grid.types';

/** Renders the cells of a column with the template of the column */
@Component({
  selector: 'pnx-grid-template-cell',
  template: `
    <ng-container *ngTemplateOutlet="template; context: context"></ng-container>
  `,
})
export class TemplateCellRendererComponent implements ICellRendererAngularComp {
  template: TemplateRef<CellContext>;
  context: CellContext;

  agInit(params: ICellRendererParams & { template: TemplateRef<CellContext> }): void {
    this.template = params.template;
    this.refresh(params);
  }

  refresh(params: ICellRendererParams): boolean {
    const grid = params.context?.grid;
    const rowIndex = grid ? grid.indexOf(params.data) : params.node?.rowIndex;
    this.context = {
      $implicit: params.data,
      row: params.data,
      value: params.value,
      rowIndex,
      index: rowIndex,
      expanded: !!grid?.isExpanded(params.data),
      toggleDetail: () => grid?.toggleDetail(params.data),
    };
    return true;
  }
}
