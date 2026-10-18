import {
  AfterContentInit,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ContentChild,
  ContentChildren,
  EventEmitter,
  Input,
  OnChanges,
  OnDestroy,
  Output,
  QueryList,
  SimpleChanges,
} from '@angular/core';
import { merge, Subject } from 'rxjs';
import { startWith, switchMap, takeUntil } from 'rxjs/operators';
import { DataColumnComponent, DataDetailDirective } from './data-column.component';
import { TemplateDetailRendererComponent } from './template-detail-renderer.component';
import {
  ColDef,
  GetRowIdParams,
  GridApi,
  GridOptions,
  GridReadyEvent,
  IRowNode,
  RowClassParams,
  RowClickedEvent,
  SelectionChangedEvent,
  SortChangedEvent,
} from 'ag-grid-community';
import { PageEvent } from '@angular/material/paginator';
import { GridColumn, GridPage, GridPageEvent, GridSort, SelectionMode } from './data-grid.types';
import { toColDefs, toGridPage, toSorts } from './data-grid.utils';

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
export class DataGridComponent implements OnChanges, AfterContentInit, OnDestroy {
  @Input() rows: any[] = [];
  /** Columns, when they are not declared with ``pnx-data-column`` */
  @Input() columns: GridColumn[] = [];
  @ContentChildren(DataColumnComponent) columnComponents: QueryList<DataColumnComponent>;
  /** Template of the detail of a row, displayed under it by ``toggleDetail`` */
  @ContentChild(DataDetailDirective) detail: DataDetailDirective;
  /** Height of the detail of a row */
  @Input() detailHeight = 120;
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
  /** Same as ``page`` for a pagination counting its pages from 1 (``currentPage``) */
  @Input() pagination: { currentPage: number; perPage: number; totalItems: number };
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
  /** Rows given to ag-grid: the rows, with the detail of the expanded ones after them */
  displayedRows: any[] = [];
  /** Given to the cell renderers */
  gridContext = { grid: this };
  private expandedRows = new Set<any>();
  /** The page displayed by the paginator */
  pageModel: GridPage;
  private destroy$ = new Subject<void>();
  private api: GridApi;

  gridOptions: GridOptions = {
    suppressCellFocus: true,
    suppressMovableColumns: false,
    animateRows: false,
    enableCellTextSelection: true,
    ensureDomOrder: true,
    suppressMultiSort: false,
    getRowClass: (params: RowClassParams) =>
      params.data?.__detail ? 'pnx-data-grid__detail-row' : this.rowClass?.(params.data),
    isFullWidthRow: (params) => !!params.rowNode.data?.__detail,
    fullWidthCellRenderer: TemplateDetailRendererComponent,
    getRowHeight: (params) => (params.data?.__detail ? this.detailHeight : undefined),
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
      this.selectionChange.emit(event.api.getSelectedRows().filter((row) => !row.__detail));
    },
    onRowClicked: (event: RowClickedEvent) => {
      if (!event.data?.__detail) {
        this.rowClick.emit({ row: event.data, event: event.event as MouseEvent });
      }
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

  constructor(private cdr: ChangeDetectorRef) {}

  ngAfterContentInit() {
    this.columnComponents.changes
      .pipe(
        startWith(null),
        switchMap(() => merge(...this.columnComponents.map((c) => c.changed))),
        takeUntil(this.destroy$)
      )
      .subscribe(() => this.refreshColumns());
    this.columnComponents.changes
      .pipe(takeUntil(this.destroy$))
      .subscribe(() => this.refreshColumns());
    this.refreshColumns();
  }

  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }

  /** Columns declared in the content, or the ones given as input */
  get allColumns(): GridColumn[] {
    return this.columnComponents?.length
      ? this.columnComponents.map((c) => c.column)
      : this.columns;
  }

  private refreshColumns() {
    this.colDefs = toColDefs(this.allColumns, {
      externalSorting: this.externalSorting,
      sorts: this.sorts ?? [],
      autoHeight: this.autoHeight,
    });
    this.cdr.markForCheck();
  }

  ngOnChanges(changes: SimpleChanges) {
    if (changes.page || changes.pagination) {
      this.pageModel = this.page ?? (this.pagination ? toGridPage(this.pagination) : undefined);
    }
    if (changes.columns || changes.sorts || changes.externalSorting || changes.rowHeight) {
      this.refreshColumns();
    }
    if (changes.rows) {
      this.expandedRows = new Set([...this.expandedRows].filter((row) => this.rows?.includes(row)));
      this.refreshRows();
    }
    if (changes.selected || changes.rows) {
      // the rows are set by the grid after the changes, wait for them
      Promise.resolve().then(() => this.syncSelection());
    }
    if (changes.loading) {
      this.syncLoading();
    }
  }

  /** Removes the sort of all the columns (the sort event is not emitted) */
  clearSort() {
    this.api?.applyColumnState({ defaultState: { sort: null } });
  }

  /** Scrolls the rows to the first one */
  scrollToTop() {
    this.api?.ensureIndexVisible(0, 'top');
  }

  /** Index of a row in the rows given to the grid */
  indexOf(row: any): number {
    return this.rows?.indexOf(row) ?? -1;
  }

  isExpanded(row: any): boolean {
    return this.expandedRows.has(row);
  }

  /** Displays the detail of the row, or hides it */
  toggleDetail(row: any) {
    if (!this.detail) {
      return;
    }
    if (!this.expandedRows.delete(row)) {
      this.expandedRows.add(row);
    }
    this.refreshRows();
    this.cdr.markForCheck();
    Promise.resolve().then(() => this.syncSelection());
  }

  private refreshRows() {
    this.displayedRows = (this.rows ?? []).flatMap((row) =>
      this.expandedRows.has(row) ? [row, { __detail: true, row }] : [row]
    );
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
    let firstSelected: IRowNode;
    this.api.forEachNode((node) => {
      if (node.data?.__detail) {
        return;
      }
      const shouldBeSelected = !!node.data && selected.has(identity(node.data));
      if (node.isSelected() !== shouldBeSelected) {
        node.setSelected(shouldBeSelected, false, 'api');
        firstSelected = firstSelected ?? (shouldBeSelected ? node : undefined);
      }
    });
    // a row selected by the caller (on a map for instance) is made visible
    if (firstSelected) {
      this.api.ensureNodeVisible(firstSelected, 'middle');
    }
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
