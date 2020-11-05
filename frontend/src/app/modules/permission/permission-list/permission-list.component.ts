import { Component, OnInit, TemplateRef, ViewChild } from '@angular/core';

import { AppConfig } from '@geonature_config/app.config';
import { DatatableComponent } from '@swimlane/ngx-datatable';
import { PermissionService } from '../permission.service';
import { IRole } from '../permission.interface'

interface DatatableColumn {
  prop: string;
  name: string;
  flexGrow: number;
  sortable?: boolean;
  tooltip?: string;
  headerClass?: string;
  cellTemplate?: TemplateRef<any>;
  headerTemplate?: TemplateRef<any>;
}

@Component({
  selector: 'pnx-permission-list',
  templateUrl: './permission-list.component.html',
  styleUrls: ['./permission-list.component.scss'],
})
export class PermissionListComponent implements OnInit {

  loadingIndicator = true;
  reorderable = true;
  swapColumns = false;

  @ViewChild(DatatableComponent)
  datatable: DatatableComponent;
  @ViewChild('colHeaderTpl')
  colHeaderTpl: TemplateRef<any>;
  @ViewChild('typeCellTpl')
  typeCellTpl: TemplateRef<any>;
  @ViewChild('actionsCellTpl')
  actionsCellTpl: TemplateRef<any>;

  columns: Array<DatatableColumn> = [
    { prop: 'id', name: '#', flexGrow: 1, tooltip: 'Identifiant du rôle.', headerClass: 'table-primary'},
    { prop: 'name', name: 'Nom', flexGrow: 3, tooltip: "Prénom et nom de l'utilisateur ou intitulé du groupe.", headerClass: 'table-primary'},
    { prop: 'type', name: 'Type', flexGrow: 2, tooltip: 'Type de rôle : groupe ou utilisateur.', headerClass: 'table-primary'},
    { prop: 'permissionsNbr', name: 'Permissions #', flexGrow: 1, tooltip: 'Nombre de permissions attribuées.', headerClass: 'table-primary'},
    { prop: 'actions', name: 'Actions', flexGrow: 1, sortable: false, headerClass: 'table-primary'},
  ];
  rows: IRole[] = [];
  filteredData = [];

  constructor(
    public permissionService: PermissionService,
  ) {
    this.permissionService.getAllRoles().subscribe(data => {
      this.loadingIndicator = false;
      this.rows = data;
      this.filteredData = [...data];
    });
  }

  ngOnInit(): void {
    this.columns.forEach(col => {
      col.headerTemplate = this.colHeaderTpl;
      if (col.prop === 'type') {
        col.cellTemplate = this.typeCellTpl;
      } else if (col.prop === 'actions') {
        col.cellTemplate = this.actionsCellTpl;
      }
    });
  }

  updateFilter(event) {
    const val = event.target.value.toLowerCase();
    // Columns to search
    let searchColumns = ['name', 'type'];
    // Get the amount of columns to search
    let searchColsAmount = searchColumns.length;

    // Filter our data
    this.rows = this.filteredData.filter(function (item) {
      // Iterate through each row's column data
      for (let i = 0; i < searchColsAmount; i++) {
        // Check for a match
        if (item[searchColumns[i]].toString().toLowerCase().indexOf(val) !== -1 || !val){
          // Found match, return true to add to result set
          return true;
        }
      }
    });

    // Whenever the filter changes, always go back to the first page
    this.datatable.offset = 0;
  }
}
