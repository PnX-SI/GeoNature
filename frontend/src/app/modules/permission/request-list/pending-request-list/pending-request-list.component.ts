import { AfterViewInit, Component, OnDestroy, OnInit, TemplateRef, ViewChild } from '@angular/core';

import { DatatableComponent, ColumnMode } from '@swimlane/ngx-datatable';
import { LangChangeEvent, TranslateService } from '@ngx-translate/core';
import { Subject } from 'rxjs';

import { PermissionRequestDatatableColumn, GnPermissionRequest } from '../../permission.interface';
import { PermissionService } from '../../permission.service';


@Component({
  selector: 'gn-pending-permission-request-list',
  templateUrl: './pending-request-list.component.html',
  styleUrls: ['./pending-request-list.component.scss'],
})
export class PendingRequestListComponent implements OnInit, OnDestroy, AfterViewInit {

  locale: string;
  destroy$: Subject<boolean> = new Subject<boolean>();

  loadingIndicator = true;
  reorderable = true;
  swapColumns = false;

  @ViewChild(DatatableComponent)
  datatable: DatatableComponent;
  @ViewChild('colHeaderTpl')
  colHeaderTpl: TemplateRef<any>;
  @ViewChild('tokenCellTpl')
  tokenCellTpl: TemplateRef<any>;
  @ViewChild('permissionCellTpl')
  permissionCellTpl: TemplateRef<any>;
  @ViewChild('endAccessDateCellTpl')
  endAccessDateCellTpl: TemplateRef<any>;
  @ViewChild('actionsCellTpl')
  actionsCellTpl: TemplateRef<any>;

  columns: Array<PermissionRequestDatatableColumn> = [
    {
      prop: 'token',
      name: '#',
      tooltip: 'Token de la demande de permission.',
      flexGrow: 1,
    },
    {
      prop: 'userName',
      name: 'Utilisateur',
      tooltip: "Prénom et nom de l'utilisateur ayant réalisé la demande.",
      flexGrow: 3,
      searchable: true,
    },
    {
      prop: 'organismName',
      name: 'Organisme',
      tooltip: "Nom de l'organisme de l'utilisateur.",
      flexGrow: 2,
      searchable: true,
    },
    {
      prop: 'permissions',
      name: 'Permissions',
      tooltip: 'Permissions demandées avec leurs éventuels filtres.',
      flexGrow: 3,
    },
    {
      prop: 'endAccessDate',
      name: 'Date de fin',
      tooltip: "Date à laquelle les permissions demandées expires.",
      flexGrow: 1,
      searchable: true,
    },
    {
      prop: 'actions',
      name: 'Actions',
      flexGrow: 2,
      sortable: false,
      headerClass: 'd-flex justify-content-end'
    },
  ];
  searchableColumnsNames: string;
  rows: GnPermissionRequest[] = [];
  filteredData = [];

  constructor(
    private translateService: TranslateService,
    public permissionService: PermissionService,
  ) {
    this.locale = translateService.currentLang;

    this.permissionService.getAllPendingRequests().subscribe(data => {
      this.loadingIndicator = false;
      this.rows = data;
      this.filteredData = [...data];
    });
  }

  ngOnInit(): void {
    this.prepareColumns();
    this.formatSearchableColumn();
    this.getI18nLocale();
  }

  ngAfterViewInit(): void {
    // Workaround to resize column with columnMode="'flex'".
    // See : https://github.com/swimlane/ngx-datatable/issues/919
    this.datatable.columnMode = ColumnMode.force;
  }

  ngOnDestroy(): void {
    this.destroy$.next(true);
    this.destroy$.unsubscribe();
  }

  private prepareColumns() {
    this.columns.forEach(col => {
      // Set common config
      col.headerTemplate = this.colHeaderTpl;
      col.headerClass += ' table-primary';

      // Set specific config
      if (col.prop === 'token') {
        col.cellTemplate = this.tokenCellTpl;
      } else if (col.prop === 'permissions') {
        col.cellTemplate = this.permissionCellTpl;
      } else if (col.prop === 'endAccessDate') {
        col.cellTemplate = this.endAccessDateCellTpl;
      } else if (col.prop === 'actions') {
        col.cellTemplate = this.actionsCellTpl;
      }
    });
  }

  private formatSearchableColumn() {
    const searchable = [];
    this.columns.forEach(col => {
      if (col.searchable) {
        searchable.push(col.name);
      }
    });
    this.searchableColumnsNames = `« ${searchable.join(' », « ')} »`;
  }

  private getI18nLocale() {
    this.locale = this.translateService.currentLang;
    // don't forget to unsubscribe!
    this.translateService.onLangChange
      .takeUntil(this.destroy$)
      .subscribe((langChangeEvent: LangChangeEvent) => {
        this.locale = langChangeEvent.lang;
        console.log(this.locale)
      });
  }

  updateFilter(event) {
    const val = event.target.value.toLowerCase();
    // Columns to search
    let searchColumns = this.getSearchableColumn();
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

  private getSearchableColumn() {
    const searchable = [];
    this.columns.forEach(col => {
      if (col.searchable) {
        searchable.push(col.prop);
      }
    });
    return searchable;
  }
}
