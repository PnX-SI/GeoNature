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
    this.context = {
      $implicit: params.data,
      row: params.data,
      value: params.value,
      rowIndex: params.node?.rowIndex,
      index: params.node?.rowIndex,
    };
    return true;
  }
}
