import { Component } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { NoopAnimationsModule } from '@angular/platform-browser/animations';
import { MatPaginatorModule } from '@angular/material/paginator';
import { AgGridModule } from 'ag-grid-angular';
import { DataGridComponent } from './data-grid.component';
import { TemplateCellRendererComponent } from './template-cell-renderer.component';
import { TemplateHeaderComponent } from './template-header.component';
import { GridColumn } from './data-grid.types';

@Component({
  template: `
    <pnx-data-grid
      [rows]="rows"
      [columns]="columns"
      [page]="page"
      height="300px"
      (pageChange)="pageChange($event)"
    ></pnx-data-grid>
    <ng-template
      #name
      let-row
    >
      <b class="cell-name">{{ row.name }}!</b>
    </ng-template>
  `,
})
class HostComponent {
  rows = [
    { id: 1, name: 'Alpha', count: 3 },
    { id: 2, name: 'Bravo', count: 5 },
  ];
  columns: GridColumn[] = [];
  page = { pageNumber: 0, perPage: 2, totalItems: 6 };
  pageChange = jest.fn();
}

describe('DataGridComponent', () => {
  let fixture: ComponentFixture<HostComponent>;
  let host: HostComponent;
  let grid: DataGridComponent;
  const root = () => fixture.nativeElement as HTMLElement;

  beforeEach(() => {
    TestBed.configureTestingModule({
      declarations: [
        DataGridComponent,
        HostComponent,
        TemplateCellRendererComponent,
        TemplateHeaderComponent,
      ],
      imports: [AgGridModule, MatPaginatorModule, NoopAnimationsModule],
    });
    fixture = TestBed.createComponent(HostComponent);
    host = fixture.componentInstance;
    host.columns = [
      { prop: 'name', name: 'Name' },
      { prop: 'count', name: 'Count' },
    ];
    fixture.detectChanges();
    grid = fixture.debugElement.children[0].componentInstance;
  });

  it('creates an ag-grid with the columns', () => {
    expect(root().querySelector('ag-grid-angular')).not.toBeNull();
    expect(grid.colDefs.map((c) => c.headerName)).toEqual(['Name', 'Count']);
  });

  it('displays a paginator with the page it receives', () => {
    const paginator = root().querySelector('mat-paginator');
    expect(paginator).not.toBeNull();
    expect(paginator.textContent).toContain('1 – 2 of 6');
  });

  it('has no paginator without page', () => {
    host.page = undefined;
    fixture.detectChanges();
    expect(root().querySelector('mat-paginator')).toBeNull();
  });

  it('emits the page asked by the user', () => {
    (root().querySelector('.mat-mdc-paginator-navigation-next') as HTMLElement).click();
    expect(host.pageChange).toHaveBeenCalledWith({ offset: 1, pageSize: 2 });
  });

  it('is as high as its rows without height', () => {
    grid.height = undefined;
    expect(grid.domLayout).toBe('autoHeight');
    grid.height = '300px';
    expect(grid.domLayout).toBe('normal');
  });

  it('lets the rows wrap their content with the automatic height', () => {
    grid.rowHeight = 'auto';
    expect(grid.autoHeight).toBe(true);
    expect(grid.fixedRowHeight).toBeUndefined();
    grid.rowHeight = 50;
    expect(grid.fixedRowHeight).toBe(50);
  });

  it('selects a single row, or several', () => {
    grid.selectionMode = 'single';
    expect(grid.rowSelection).toBe('single');
    grid.selectionMode = 'multiple';
    expect(grid.rowSelection).toBe('multiple');
  });

  it('emits the selection of the user, not the one of the api', () => {
    const selected = jest.fn();
    grid.selectionChange.subscribe(selected);
    const getSelectedRows = jest.fn().mockReturnValue([host.rows[0]]);
    grid.gridOptions.onSelectionChanged({
      source: 'api',
      api: { getSelectedRows },
    } as any);
    expect(selected).not.toHaveBeenCalled();
    grid.gridOptions.onSelectionChanged({
      source: 'rowClicked',
      api: { getSelectedRows },
    } as any);
    expect(selected).toHaveBeenCalledWith([host.rows[0]]);
  });

  it('emits the sorts of the user, not the ones of the api', () => {
    const sorted = jest.fn();
    grid.sortChange.subscribe(sorted);
    const api = { getColumnState: () => [{ colId: 'name', sort: 'asc', sortIndex: 0 }] };
    grid.gridOptions.onSortChanged({ source: 'api', api } as any);
    expect(sorted).not.toHaveBeenCalled();
    grid.gridOptions.onSortChanged({ source: 'uiColumnSorted', api } as any);
    expect(sorted).toHaveBeenCalledWith([{ prop: 'name', dir: 'asc' }]);
  });

  it('gives the row and the class of a row to the callers', () => {
    grid.rowClass = (row) => `row-${row.id}`;
    grid.rowId = (row) => String(row.id);
    expect(grid.gridOptions.getRowClass({ data: host.rows[0] } as any)).toBe('row-1');
    expect(grid.getRowId({ data: host.rows[1] } as any)).toBe('2');
  });

  it('emits the clicked row', () => {
    const clicked = jest.fn();
    grid.rowClick.subscribe(clicked);
    const event = new MouseEvent('click');
    grid.gridOptions.onRowClicked({ data: host.rows[1], event } as any);
    expect(clicked).toHaveBeenCalledWith({ row: host.rows[1], event });
  });
});
