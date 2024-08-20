import { Component, Input,OnInit, Output, EventEmitter, ViewChild } from '@angular/core';
import { GenericTableComponent } from './generic-table.component';

@Component({
  selector: 'pnx-home-discussions-table',
  templateUrl: './home-discussions-table.component.html',
  styleUrls: ['./home-discussions-table.component.scss'],
})

export class HomeDiscussionsTableComponent {
  @Input() discussions = [];
  @Input() columns = [];
  @Input() currentPage = 1;
  @Input() perPage = 2;
  @Input() totalPages = 1;
  @Input() totalRows = 0;

  @Output() rowClick = new EventEmitter<any>();
  @Output() columnSort = new EventEmitter<any>();
  @Output() pageChange = new EventEmitter<any>();

  @ViewChild(GenericTableComponent, { static: false }) genericTable!: GenericTableComponent;

  constructor() {}

  // TODO: voir pour utiliser ce composant concernant les méthode "columSort" et "pageChange"
  handleExpandRow(row: any) {
    this.genericTable.table.rowDetail.toggleExpandRow(row);
  }
}