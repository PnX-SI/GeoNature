import { Component, ContentChild, Directive, Input, OnChanges, TemplateRef } from '@angular/core';
import { Subject } from 'rxjs';
import { CellContext, DetailContext, GridColumn } from './data-grid.types';

/** Marks the template of the cells of a ``pnx-data-column`` (``let-row="row"``, ``let-value="value"``) */
@Directive({ selector: 'ng-template[pnxDataCell]' })
export class DataCellDirective {
  constructor(public template: TemplateRef<CellContext>) {}
}

/** Marks the template of the header of a ``pnx-data-column`` */
@Directive({ selector: 'ng-template[pnxDataHeader]' })
export class DataHeaderDirective {
  constructor(public template: TemplateRef<{ $implicit: GridColumn }>) {}
}

/**
 * Marks the template of the detail of a row, a direct child of ``pnx-data-grid``. The detail is
 * displayed under the row when the template of a cell calls ``toggleDetail()``.
 */
@Directive({ selector: 'ng-template[pnxDataDetail]' })
export class DataDetailDirective {
  constructor(public template: TemplateRef<DetailContext>) {}
}

/**
 * Column of a ``pnx-data-grid``, declared in its content.
 *
 * @example
 * <pnx-data-grid [rows]="rows">
 *   <pnx-data-column prop="name" name="Name" [sortable]="true"></pnx-data-column>
 *   <pnx-data-column prop="id" name="Link">
 *     <ng-template pnxDataCell let-row="row"><a [href]="row.url">{{ row.id }}</a></ng-template>
 *   </pnx-data-column>
 * </pnx-data-grid>
 */
@Component({
  selector: 'pnx-data-column',
  template: '',
})
export class DataColumnComponent implements OnChanges {
  @Input() prop: string;
  @Input() name: string;
  @Input() width: number;
  @Input() minWidth: number;
  @Input() maxWidth: number;
  @Input() flex: number;
  @Input() sortable: boolean;
  @Input() resizable: boolean;
  @Input() pinned: 'left' | 'right';
  @Input() hidden: boolean;
  @Input() cellClass: string | string[];
  @Input() checkbox: boolean;
  @Input() valueGetter: (row: any) => any;
  @Input() comparator: (a: any, b: any) => number;
  @Input() valueFormatter: (value: any, row: any) => string;

  @ContentChild(DataCellDirective) cell: DataCellDirective;
  @ContentChild(DataHeaderDirective) header: DataHeaderDirective;

  /** Emits when an input changes, for the grid to rebuild its columns */
  readonly changed = new Subject<void>();

  ngOnChanges() {
    this.changed.next();
  }

  get column(): GridColumn {
    return {
      prop: this.prop,
      name: this.name,
      width: this.width,
      minWidth: this.minWidth,
      maxWidth: this.maxWidth,
      checkbox: this.checkbox,
      valueGetter: this.valueGetter,
      comparator: this.comparator,
      flex: this.flex,
      sortable: this.sortable,
      resizable: this.resizable,
      pinned: this.pinned,
      hidden: this.hidden,
      cellClass: this.cellClass,
      valueFormatter: this.valueFormatter,
      template: this.cell?.template,
      headerTemplate: this.header?.template,
    };
  }
}
