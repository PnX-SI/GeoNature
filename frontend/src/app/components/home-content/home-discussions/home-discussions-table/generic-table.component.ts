import { Component, Input, Output, EventEmitter, ContentChild, TemplateRef, OnInit, ViewChild } from '@angular/core';
import { DatatableComponent } from '@swimlane/ngx-datatable';

@Component({
  selector: 'generic-table',
  templateUrl: './generic-table.component.html',
  styleUrls: ['./generic-table.component.scss']
})
export class GenericTableComponent implements OnInit {
  @Input() rows: any[] = [];
  @Input() columns: any[] = [];
  @Input() headerHeight: number = 50;
  @Input() footerHeight: number = 50;
  @Input() rowHeight: string | number = 'auto';
  @Input() limit: number = 10;
  @Input() count: number = 0;
  @Input() offset: number = 0;
  @Input() columnMode: string = 'force';
  @Input() rowDetailHeight: number = 150;
  @Input() customTemplateColumn: string | null = null;
  @Input() totalRows: number = 0;

  @Output() onRowSelect = new EventEmitter<any>();
  @Output() onColumnSort = new EventEmitter<any>();
  @Output() onToggleExpandRow = new EventEmitter<any>();

  // TODO: utiliser ces templates pour pouvoir rendre le composant customisable avec du contenu qu'on lui fourni
  @ContentChild('rowDetailTemplate') rowDetailTemplate: TemplateRef<any> | null = null;
  @ContentChild('customCellTemplate') customCellTemplate: TemplateRef<any> | null = null;
  @ContentChild('footerTemplate') footerTemplate: TemplateRef<any> | null = null;

  @ViewChild('table', { static: false }) table: DatatableComponent | undefined;
  constructor() {}

  ngOnInit() {
  }

}
