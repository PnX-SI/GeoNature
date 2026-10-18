import {
  ChangeDetectionStrategy,
  Component,
  EventEmitter,
  Input,
  OnChanges,
  Output,
  SimpleChanges,
} from '@angular/core';
import {
  ColDef,
  GetRowIdParams,
  GridApi,
  GridOptions,
  GridReadyEvent,
  RowClassParams,
  RowClickedEvent,
  SelectionChangedEvent,
  SortChangedEvent,
} from 'ag-grid-community';
import { PageEvent } from '@angular/material/paginator';
import { GridColumn, GridPage, GridPageEvent, GridSort, SelectionMode } from './data-grid.types';
import { toColDefs, toSorts } from './data-grid.utils';

/**
 * Table of rows (AG Grid). It only knows the rows, the columns and the state (page, sorts,
 * selection) it receives, and emits the changes asked by the user: the caller loads the pages,
 * sorts the rows and keeps the selection.
 *
 * @example
 * <pnx-data-grid
 *   [rows]="rows"
 *   [columns]="columns"
 *   [page]="{ pageNumber: 0, perPage: 50, totalItems: 120 }"
 *   [sorts]="[{ prop: 'date', dir: 'desc' }]"
 *   [externalSorting]="true"
 *   (pageChange)="load($event.offset, $event.pageSize)"
 *   (sortChange)="sort($event)"
 * ></pnx-data-grid>
 */
@Component({
  selector: 'pnx-data-grid',
  templateUrl: './data-grid.component.html',
  styleUrls: ['./data-grid.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class DataGridComponent implements OnChanges {
  @Input() rows: any[] = [];
  @Input() columns: GridColumn[] = [];
  @Input() loading = false;
  /** Height of the rows. ``auto`` lets the cells wrap their content */
  @Input() rowHeight: number | 'auto' = 40;
  @Input() headerHeight = 40;
  /** Height of the table, in CSS. The table is as high as its rows when not given */
  @Input() height: string;
  /** Text displayed when there is no row */
  @Input() emptyMessage = 'Aucune donnée';
  /** Pagination managed by the caller. Without it, the rows are not paginated */
  @Input() page: GridPage;
  @Input() pageSizeOptions: number[] = [10, 25, 50, 100];
  /** Sorts displayed in the headers */
  @Input() sorts: GridSort[] = [];
  /** The sort is done by the caller (the grid does not reorder the rows) */
  @Input() externalSorting = false;
  @Input() selectionMode: SelectionMode = 'none';
  /** Selected rows */
  @Input() selected: any[] = [];
  /** CSS classes of the row */
  @Input() rowClass: (row: any) => string | string[];
  /** Identity of a row, used to keep the selection when the rows are reloaded */
  @Input() rowId: (row: any) => string;
  @Input() dataQa: string;

  @Output() pageChange = new EventEmitter<GridPageEvent>();
  @Output() sortChange = new EventEmitter<GridSort[]>();
  /** The rows selected by the user */
  @Output() selectionChange = new EventEmitter<any[]>();
  /** A row has been clicked */
  @Output() rowClick = new EventEmitter<{ row: any; event: MouseEvent }>();

  colDefs: ColDef[] = [];
  private api: GridApi;

  gridOptions: GridOptions = {
    suppressCellFocus: true,
    suppressMovableColumns: false,
    animateRows: false,
    enableCellTextSelection: true,
    ensureDomOrder: true,
    suppressMultiSort: false,
    getRowClass: (params: RowClassParams) => this.rowClass?.(params.data),
    onGridReady: (event: GridReadyEvent) => {
      this.api = event.api;
      this.syncSelection();
      this.syncLoading();
    },
    onSortChanged: (event: SortChangedEvent) => {
      if (event.source === 'api') {
        return;
      }
      this.sortChange.emit(toSorts(event.api.getColumnState()));
    },
    onSelectionChanged: (event: SelectionChangedEvent) => {
      if (event.source === 'api') {
        return;
      }
      this.selectionChange.emit(event.api.getSelectedRows());
    },
    onRowClicked: (event: RowClickedEvent) => {
      this.rowClick.emit({ row: event.data, event: event.event as MouseEvent });
    },
  };

  /** Only given to the grid with a ``rowId``: without it the grid numbers the rows itself */
  getRowId = (params: GetRowIdParams): string => this.rowId(params.data);

  get autoHeight(): boolean {
    return this.rowHeight === 'auto';
  }

  get domLayout(): 'autoHeight' | 'normal' {
    return this.height ? 'normal' : 'autoHeight';
  }

  get rowSelection(): 'single' | 'multiple' {
    return this.selectionMode === 'multiple' ? 'multiple' : 'single';
  }

  get gridHeight(): string {
    return this.height ?? null;
  }

  get fixedRowHeight(): number {
    return this.autoHeight ? undefined : (this.rowHeight as number);
  }

  ngOnChanges(changes: SimpleChanges) {
    if (changes.columns || changes.sorts || changes.externalSorting || changes.rowHeight) {
      this.colDefs = toColDefs(this.columns, {
        externalSorting: this.externalSorting,
        sorts: this.sorts ?? [],
        autoHeight: this.autoHeight,
      });
    }
    if (changes.selected || changes.rows) {
      // the rows are set by the grid after the changes, wait for them
      Promise.resolve().then(() => this.syncSelection());
    }
    if (changes.loading) {
      this.syncLoading();
    }
  }

  onPage(event: PageEvent) {
    this.pageChange.emit({ offset: event.pageIndex, pageSize: event.pageSize });
  }

  private syncSelection() {
    if (!this.api || this.selectionMode === 'none') {
      return;
    }
    const identity = (row: any) => (this.rowId ? this.rowId(row) : row);
    const selected = new Set((this.selected ?? []).map(identity));
    this.api.forEachNode((node) => {
      const shouldBeSelected = !!node.data && selected.has(identity(node.data));
      if (node.isSelected() !== shouldBeSelected) {
        node.setSelected(shouldBeSelected, false, 'api');
      }
    });
  }

  private syncLoading() {
    if (this.loading) {
      this.api?.showLoadingOverlay();
    } else {
      this.api?.hideOverlay();
      if (!this.rows?.length) {
        this.api?.showNoRowsOverlay();
      }
    }
  }
}
