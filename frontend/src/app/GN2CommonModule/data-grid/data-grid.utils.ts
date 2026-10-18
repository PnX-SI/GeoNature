import { ColDef } from 'ag-grid-community';
import { GridColumn, GridPage, GridSort } from './data-grid.types';
import { TemplateCellRendererComponent } from './template-cell-renderer.component';
import { TemplateHeaderComponent } from './template-header.component';

export interface ColumnOptions {
  /** The sort is done by the caller: the grid must not reorder the rows it receives */
  externalSorting: boolean;
  sorts: GridSort[];
  /** Rows of automatic height (cells wrap their content) */
  autoHeight: boolean;
}

/** Definition of the columns of ag-grid for the columns of a ``pnx-data-grid`` */
export function toColDefs(columns: GridColumn[], options: ColumnOptions): ColDef[] {
  return (columns ?? []).map((column) => {
    const sort = options.sorts.find((s) => s.prop === column.prop);
    const colDef: ColDef = {
      colId: column.prop,
      field: column.prop,
      headerName: column.name ?? column.prop,
      width: column.width,
      minWidth: column.minWidth,
      flex: column.width ? undefined : (column.flex ?? 1),
      sortable: column.sortable ?? false,
      resizable: column.resizable ?? true,
      pinned: column.pinned,
      hide: column.hidden,
      cellClass: column.cellClass,
      sort: sort?.dir ?? null,
      sortIndex: sort ? options.sorts.indexOf(sort) : null,
      wrapText: options.autoHeight,
      autoHeight: options.autoHeight,
    };
    if (options.externalSorting) {
      colDef.comparator = () => 0;
    }
    if (column.valueFormatter) {
      colDef.valueFormatter = ({ value, data }) => column.valueFormatter(value, data);
    }
    if (column.template) {
      colDef.cellRenderer = TemplateCellRendererComponent;
      colDef.cellRendererParams = { template: column.template };
    }
    if (column.headerTemplate) {
      colDef.headerComponent = TemplateHeaderComponent;
      colDef.headerComponentParams = { gridColumn: column };
    }
    return colDef;
  });
}

/** The sorts of the columns state of ag-grid, by priority */
export function toSorts(
  state: Array<{ colId: string; sort?: 'asc' | 'desc' | null; sortIndex?: number | null }>
): GridSort[] {
  return state
    .filter((column) => !!column.sort)
    .sort((a, b) => (a.sortIndex ?? 0) - (b.sortIndex ?? 0))
    .map((column) => ({ prop: column.colId, dir: column.sort }));
}

/** Page of a ``pnx-data-grid`` for a pagination counting its pages from 1 */
export function toGridPage(pagination: {
  currentPage: number;
  perPage: number;
  totalItems: number;
}): GridPage {
  return {
    pageNumber: Math.max((pagination.currentPage ?? 1) - 1, 0),
    perPage: pagination.perPage,
    totalItems: pagination.totalItems,
  };
}
