import { Component } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { NoopAnimationsModule } from '@angular/platform-browser/animations';
import { MatPaginatorModule } from '@angular/material/paginator';
import { AgGridModule } from 'ag-grid-angular';
import { DataGridComponent } from './data-grid.component';
import {
  DataCellDirective,
  DataColumnComponent,
  DataDetailDirective,
  DataHeaderDirective,
} from './data-column.component';
import { TemplateCellRendererComponent } from './template-cell-renderer.component';
import { TemplateDetailRendererComponent } from './template-detail-renderer.component';
import { TemplateHeaderComponent } from './template-header.component';

@Component({
  template: `
    <pnx-data-grid
      [rows]="rows"
      height="300px"
      selectionMode="single"
      [selected]="selected"
    >
      <pnx-data-column
        prop="name"
        name="Name"
      ></pnx-data-column>
      <ng-template
        pnxDataDetail
        let-row="row"
      >
        <span class="detail-text">Detail of {{ row.name }}</span>
      </ng-template>
    </pnx-data-grid>
  `,
})
class HostComponent {
  rows = [{ name: 'Alpha' }, { name: 'Bravo' }, { name: 'Charlie' }];
  selected = [];
}

describe('DataGridComponent detail rows', () => {
  let fixture: ComponentFixture<HostComponent>;
  let host: HostComponent;
  let grid: DataGridComponent;

  beforeEach(() => {
    TestBed.configureTestingModule({
      declarations: [
        DataGridComponent,
        DataColumnComponent,
        DataCellDirective,
        DataHeaderDirective,
        DataDetailDirective,
        TemplateCellRendererComponent,
        TemplateDetailRendererComponent,
        TemplateHeaderComponent,
        HostComponent,
      ],
      imports: [AgGridModule, MatPaginatorModule, NoopAnimationsModule],
    });
    fixture = TestBed.createComponent(HostComponent);
    host = fixture.componentInstance;
    fixture.detectChanges();
    grid = fixture.debugElement.children[0].componentInstance;
  });

  it('gives the rows to the grid, without detail', () => {
    expect(grid.displayedRows).toEqual(host.rows);
  });

  it('displays the detail of a row after it', () => {
    grid.toggleDetail(host.rows[1]);
    expect(grid.displayedRows).toEqual([
      host.rows[0],
      host.rows[1],
      { __detail: true, row: host.rows[1] },
      host.rows[2],
    ]);
    expect(grid.isExpanded(host.rows[1])).toBe(true);
    expect(grid.isExpanded(host.rows[0])).toBe(false);
  });

  it('hides the detail of a row when toggled again', () => {
    grid.toggleDetail(host.rows[1]);
    grid.toggleDetail(host.rows[1]);
    expect(grid.displayedRows).toEqual(host.rows);
  });

  it('gives the index of a row among the rows, not the displayed ones', () => {
    grid.toggleDetail(host.rows[0]);
    expect(grid.indexOf(host.rows[2])).toBe(2);
  });

  it('forgets the detail of the rows that are not given anymore', () => {
    grid.toggleDetail(host.rows[0]);
    host.rows = [host.rows[1], host.rows[2]];
    fixture.detectChanges();
    expect(grid.displayedRows).toEqual(host.rows);
  });

  it('gives a full width row and a height to the detail rows', () => {
    expect(grid.gridOptions.isFullWidthRow({ rowNode: { data: { __detail: true } } } as any)).toBe(
      true
    );
    expect(grid.gridOptions.isFullWidthRow({ rowNode: { data: host.rows[0] } } as any)).toBe(false);
    expect(grid.gridOptions.getRowHeight({ data: { __detail: true } } as any)).toBe(120);
    expect(grid.gridOptions.getRowHeight({ data: host.rows[0] } as any)).toBeUndefined();
  });

  it('does not emit the click or the selection of a detail row', () => {
    const clicked = jest.fn();
    const selected = jest.fn();
    grid.rowClick.subscribe(clicked);
    grid.selectionChange.subscribe(selected);
    grid.gridOptions.onRowClicked({ data: { __detail: true, row: host.rows[0] } } as any);
    expect(clicked).not.toHaveBeenCalled();
    grid.gridOptions.onSelectionChanged({
      source: 'rowClicked',
      api: { getSelectedRows: () => [host.rows[0], { __detail: true, row: host.rows[0] }] },
    } as any);
    expect(selected).toHaveBeenCalledWith([host.rows[0]]);
  });
});
