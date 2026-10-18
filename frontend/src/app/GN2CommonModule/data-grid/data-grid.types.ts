import { TemplateRef } from '@angular/core';

/** Context of the templates of a cell: the row and the value of the column in this row */
export interface CellContext {
  $implicit: any;
  row: any;
  value: any;
  /** Index of the row in the page displayed */
  rowIndex: number;
  /** Same as ``rowIndex`` */
  index: number;
  /** The detail of the row is displayed */
  expanded: boolean;
  /** Displays or hides the detail of the row */
  toggleDetail: () => void;
}

/** Context of the template of the detail of a row */
export interface DetailContext {
  $implicit: any;
  row: any;
}

/** Column of a ``pnx-data-grid`` */
export interface GridColumn {
  /** Attribute of the row displayed in the column. Nested attributes ("a.b") are allowed */
  prop: string;
  /** Header of the column, the ``prop`` by default */
  name?: string;
  width?: number;
  minWidth?: number;
  maxWidth?: number;
  /** Share of the remaining width the column takes, when it has no ``width`` */
  flex?: number;
  sortable?: boolean;
  resizable?: boolean;
  pinned?: 'left' | 'right';
  hidden?: boolean;
  /** Template of the cells. The row is its implicit context */
  template?: TemplateRef<CellContext>;
  /** Template of the header, ``{ $implicit: column }`` */
  headerTemplate?: TemplateRef<{ $implicit: GridColumn }>;
  cellClass?: string | string[];
  /** The cells have a checkbox selecting the row, and the header one selecting all the rows */
  checkbox?: boolean;
  /** Value of the cells, when it is not the ``prop`` attribute of the row (used to sort) */
  valueGetter?: (row: any) => any;
  /** Compares two values of the column, for a sort done by the grid */
  comparator?: (a: any, b: any) => number;
  /** Format the value of the cells (the template, when given, replaces it) */
  valueFormatter?: (value: any, row: any) => string;
}

export type SortDirection = 'asc' | 'desc';

export interface GridSort {
  prop: string;
  dir: SortDirection;
}

/** Pagination managed by the caller (the page of rows is the one it gives) */
export interface GridPage {
  /** Index of the current page, from 0 */
  pageNumber: number;
  perPage: number;
  totalItems: number;
}

export interface GridPageEvent {
  /** Index of the page to display, from 0 */
  offset: number;
  pageSize: number;
}

export type SelectionMode = 'none' | 'single' | 'multiple';
