import { CommonModule } from '@angular/common';
import { Component, Input, Output, EventEmitter, ViewChild } from '@angular/core';
import { Router } from '@angular/router';
import { GN2CommonModule } from '@geonature_common/GN2Common.module';
import { DatatableComponent } from '@swimlane/ngx-datatable';

@Component({
  standalone: true,
  selector: 'pnx-home-discussions-table',
  templateUrl: './home-discussions-table.component.html',
  styleUrls: ['./home-discussions-table.component.scss'],
  imports: [GN2CommonModule, CommonModule],
})
export class HomeDiscussionsTableComponent {
  @Input() discussions = [];
  @Input() currentPage = 1;
  @Input() perPage = 2;
  @Input() totalPages = 1;
  @Input() totalRows = 0;
  @Input() totalFilteredRows = 0;
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
  orderby = 'creation_date';

  @Output() sortChange = new EventEmitter<Object>();
  @Output() orderbyChange = new EventEmitter<string>();
  @Output() currentPageChange = new EventEmitter<number>();

  @ViewChild('table', { static: false }) table: DatatableComponent | undefined;

  constructor(private _router: Router) {}

  ngOnInit() {
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
    this.sortChange.emit({ sort: this.sort, orderby: this.orderby });
  }

  onRowClick(row: any) {
    // TODO: ajouter au chemin 'discussions' une fois que la PR https://github.com/PnX-SI/GeoNature/pull/3169 a été reviewed et mergé
    this._router.navigate(['/synthese', 'occurrence', row.id_synthese]);
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
