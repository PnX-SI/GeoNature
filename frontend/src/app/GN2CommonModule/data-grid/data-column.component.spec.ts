import { Component } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { NoopAnimationsModule } from '@angular/platform-browser/animations';
import { MatPaginatorModule } from '@angular/material/paginator';
import { AgGridModule } from 'ag-grid-angular';
import { DataGridComponent } from './data-grid.component';
import {
  DataCellDirective,
  DataColumnComponent,
  DataHeaderDirective,
} from './data-column.component';
import { TemplateCellRendererComponent } from './template-cell-renderer.component';
import { TemplateHeaderComponent } from './template-header.component';

@Component({
  template: `
    <pnx-data-grid
      [rows]="rows"
      height="300px"
      [pagination]="{ currentPage: 2, perPage: 2, totalItems: 6 }"
    >
      <pnx-data-column
        prop="name"
        name="Name"
        [sortable]="true"
      ></pnx-data-column>
      <pnx-data-column
        *ngFor="let col of extra"
        [prop]="col"
        [name]="col"
        [width]="width"
      >
        <ng-template
          pnxDataCell
          let-row="row"
          let-index="rowIndex"
        >
          <i>{{ row.name }}-{{ index }}</i>
        </ng-template>
        <ng-template
          pnxDataHeader
          let-column
        >
          <u>{{ column.name }}!</u>
        </ng-template>
      </pnx-data-column>
    </pnx-data-grid>
  `,
})
class HostComponent {
  rows = [{ name: 'Alpha', count: 1 }];
  extra = ['count'];
  width = 100;
}

describe('pnx-data-column', () => {
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
        TemplateCellRendererComponent,
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

  it('builds the columns of the grid from the declared columns', () => {
    expect(grid.colDefs.map((c) => c.headerName)).toEqual(['Name', 'count']);
    expect(grid.colDefs[0].sortable).toBe(true);
    expect(grid.colDefs[1].width).toBe(100);
  });

  it('gives the cell and header templates of the column', () => {
    expect(grid.colDefs[1].cellRenderer).toBe(TemplateCellRendererComponent);
    expect(grid.colDefs[1].headerComponent).toBe(TemplateHeaderComponent);
    expect(grid.colDefs[0].cellRenderer).toBeUndefined();
  });

  it('follows the columns added and removed', () => {
    host.extra = ['count', 'other'];
    fixture.detectChanges();
    expect(grid.colDefs.map((c) => c.colId)).toEqual(['name', 'count', 'other']);
    host.extra = [];
    fixture.detectChanges();
    expect(grid.colDefs.map((c) => c.colId)).toEqual(['name']);
  });

  it('follows the inputs of the columns', () => {
    host.width = 250;
    fixture.detectChanges();
    expect(grid.colDefs[1].width).toBe(250);
  });

  it('counts the pages of a pagination from 1', () => {
    expect(grid.pageModel).toEqual({ pageNumber: 1, perPage: 2, totalItems: 6 });
  });
});
