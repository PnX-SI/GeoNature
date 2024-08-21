import { Component, Input, Output, EventEmitter, ViewChild } from '@angular/core';
import { DatatableComponent } from '@swimlane/ngx-datatable';

@Component({
  selector: 'pnx-home-discussions-table',
  templateUrl: './home-discussions-table.component.html',
  styleUrls: ['./home-discussions-table.component.scss'],
})

export class HomeDiscussionsTableComponent {
  @Input() discussions = [];
  @Input() currentPage = 1;
  @Input() perPage = 2;
  @Input() totalPages = 1;
  @Input() totalRows = 0;
  headerHeight: number = 50;
  footerHeight: number = 50;
  rowHeight: string | number = 'auto';
  limit: number = 10;
  count: number = 0;
  offset: number = 0;
  columnMode: string = 'force';
  rowDetailHeight: number = 150;
  columns = [];
  sort = 'desc';
  orderby = 'date';

  @Output() sortChange = new EventEmitter<string>();
  @Output() orderbyChange = new EventEmitter<string>();
  @Output() currentPageChange = new EventEmitter<number>();

  @ViewChild('table', { static: false }) table: DatatableComponent | undefined;

  constructor() {}

  ngOnInit() {
    console.log("totalRows", this.totalRows);
    this.columns = this.getColumnsConfig();
  }

  handleExpandRow(row: any) {
    this.table.rowDetail.toggleExpandRow(row);
  }

  handlePageChange(event: any) {
    this.currentPage = event.page;
    this.currentPageChange.emit(this.currentPage);
  }

  onColumnSort(event: any) {
    this.sort = event.sorts[0].dir;
    this.orderby = event.sorts[0].prop;
    this.sortChange.emit(this.sort);
    this.orderbyChange.emit(this.orderby);
  }

  onRowClick(event: any) {
    // TODO: à pointer vers la route /synthese/occurence/:id_synthese/tab_discussion (qui sera fait dans une autre PR)
    console.log('Clicked row:', event.row);
  }

  getColumnsConfig() {
    return [
      { prop: 'creation_date', name: 'Date commentaire', sortable: true },
      { prop: 'user.nom_complet', name: 'Auteur', sortable: true },
      { prop: 'content', name: 'Contenu', sortable: true },
      { prop: 'observation', name: 'Observation', sortable: false, maxWidth: 500 },
    ];
  }

}