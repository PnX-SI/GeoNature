import { Component, TemplateRef } from '@angular/core';
import { ICellRendererAngularComp } from 'ag-grid-angular';
import { ICellRendererParams } from 'ag-grid-community';
import { DetailContext } from './data-grid.types';

/** Renders the detail of a row, in a row taking the whole width of the grid */
@Component({
  selector: 'pnx-grid-detail',
  template: `
    <div class="pnx-data-grid__detail">
      <ng-container *ngTemplateOutlet="template; context: context"></ng-container>
    </div>
  `,
})
export class TemplateDetailRendererComponent implements ICellRendererAngularComp {
  template: TemplateRef<DetailContext>;
  context: DetailContext;

  agInit(params: ICellRendererParams): void {
    this.refresh(params);
  }

  refresh(params: ICellRendererParams): boolean {
    const grid = params.context.grid;
    this.template = grid.detail.template;
    this.context = { $implicit: params.data.row, row: params.data.row };
    return true;
  }
}
