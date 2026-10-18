import { Component, TemplateRef } from '@angular/core';
import { IHeaderAngularComp } from 'ag-grid-angular';
import { IHeaderParams } from 'ag-grid-community';
import { GridColumn } from './data-grid.types';

/** Renders the header of a column with the header template of the column */
@Component({
  selector: 'pnx-grid-template-header',
  template: `
    <ng-container *ngTemplateOutlet="template; context: { $implicit: column }"></ng-container>
  `,
})
export class TemplateHeaderComponent implements IHeaderAngularComp {
  template: TemplateRef<{ $implicit: GridColumn }>;
  column: GridColumn;

  agInit(params: IHeaderParams & { gridColumn: GridColumn }): void {
    this.column = params.gridColumn;
    this.template = this.column.headerTemplate;
  }

  refresh(): boolean {
    return false;
  }
}
