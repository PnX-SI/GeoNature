import {
  Component,
  OnInit,
  Input,
  ViewChild,
  HostListener,
  AfterContentChecked,
  OnChanges,
  ChangeDetectorRef,
} from '@angular/core';
import { GeoJSON } from 'leaflet';
import { MapListService } from '@geonature_common/map-list/map-list.service';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { SyntheseFormService } from '@geonature_common/form/synthese-form/synthese-form.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { CommonService } from '@geonature_common/service/common.service';
import { HttpParams } from '@angular/common/http/';
import { DomSanitizer } from '@angular/platform-browser';
import { SyntheseModalDownloadComponent } from './modal-download/modal-download.component';
// import { DatatableComponent } from '@swimlane/ngx-datatable';
import { DatatableComponent } from '@swimlane/ngx-datatable';
import { ColumnMode } from '@swimlane/ngx-datatable';
import { CruvedStoreService } from '@geonature_common/service/cruved-store.service';
import { SyntheseInfoObsComponent } from '@geonature/shared/syntheseSharedModule/synthese-info-obs/synthese-info-obs.component';
import { ConfigService } from '@geonature/services/config.service';
import { ModuleService } from '@geonature/services/module.service';

@Component({
  selector: 'pnx-synthese-list',
  templateUrl: 'synthese-list.component.html',
  styleUrls: ['synthese-list.component.scss'],
})
export class SyntheseListComponent implements OnInit, OnChanges, AfterContentChecked {
  public SYNTHESE_CONFIG = null;
  public selectedObs: any;
  public selectObsTaxonInfo: any;
  public selectedObsTaxonDetail: any;
  public previousRow: any;
  public rowNumber: number;
  public queyrStringDownload: HttpParams;
  public inpnMapUrl: string;
  public downloadMessage: string;
  public ColumnMode: ColumnMode;
  public availableColumns: Array<any> = [];
  public defaultColumns: Array<any> = [];
  //input to resize datatable on searchbar toggle
  @Input() searchBarHidden: boolean;
  @Input() inputSyntheseData: GeoJSON;
  @ViewChild('table', { static: true }) table: DatatableComponent;
  private _latestWidth: number;
  public destinationImportCode: string;

  constructor(
    public mapListService: MapListService,
    public ngbModal: NgbModal,
    public sanitizer: DomSanitizer,
    public ref: ChangeDetectorRef,
    public _cruvedStore: CruvedStoreService,
    public config: ConfigService,
    private _moduleService: ModuleService
  ) {
    this.SYNTHESE_CONFIG = this.config.SYNTHESE;
    const currentModule = this._moduleService.currentModule;
    this.destinationImportCode = currentModule.module_code.toLowerCase();
    
  }

  ngOnInit() {
    // get wiewport height to set the number of rows in the tabl
    const h = document.documentElement.clientHeight;
    this.rowNumber = Math.trunc(h / 37);

    this.initListColumns();

    // On map click, select on the list a change the page
    this.mapListService.onMapClik$.subscribe((ids) => {
      this.resetSorting();

      this.mapListService.tableData.map((row) => {
        // mandatory to sort (each row must have a selected attr)
        row.selected = false;
        if (ids.includes(row.id_synthese)) {
          row.selected = true;
        }
      });

      let observations = this.mapListService.tableData.filter((e) => {
        return ids.includes(e.id_synthese);
      });

      this.mapListService.tableData.sort((a, b) => {
        return b.selected - a.selected;
      });
      this.mapListService.tableData = [...this.mapListService.tableData];
      this.mapListService.selectedRow = observations;
      const page = Math.trunc(
        this.mapListService.tableData.findIndex((e) => {
          return e.id_synthese === ids[0];
        }) / this.rowNumber
      );
      this.table.offset = page;
    });
  }

  ngAfterContentChecked() {
    if (this.table && this.table.element.clientWidth !== this._latestWidth) {
      this._latestWidth = this.table.element.clientWidth;
      if (this.searchBarHidden) {
        this.table.recalculate();
        this.ref.markForCheck();
      }
    }
  }

  private resetSorting() {
    this.table.sorts = [];
  }

  initListColumns() {
    this.defaultColumns = this.SYNTHESE_CONFIG.LIST_COLUMNS_FRONTEND;
    let allColumnsTemp = [
      ...this.SYNTHESE_CONFIG.LIST_COLUMNS_FRONTEND,
      ...this.SYNTHESE_CONFIG.ADDITIONAL_COLUMNS_FRONTEND,
    ];
    this.availableColumns = allColumnsTemp.map((col) => {
      col['checked'] = this.defaultColumns.some((defcol) => {
        return defcol.name == col.name;
      });
      return col;
    });
  }

  /**
   * Restore previous selected rows when sort state return to 'undefined'.
   * With ngx-datable sortType must be 'multi' to use 3 states : asc, desc and undefined !
   * @param event sort event infos.
   */
  onSort(event) {
    if (event.newValue === undefined) {
      let selectedObsIds = this.mapListService.selectedRow.map((obs) => obs.id_synthese);
      this.mapListService.mapSelected.next(selectedObsIds);
    }
  }

  // update the number of row per page when resize the window
  @HostListener('window:resize', ['$event'])
  onResize(event) {
    this.rowNumber = Math.trunc(event.target.innerHeight / 37);
  }

  backToModule(url_source, id_pk_source) {
    const link = document.createElement('a');
    link.target = '_blank';
    link.href = url_source + '/' + id_pk_source;
    link.setAttribute('visibility', 'hidden');
    document.body.appendChild(link);
    link.click();
    link.remove();
  }

  openInfoModal(row) {
    row.id_synthese = row.id_synthese;
    const modalRef = this.ngbModal.open(SyntheseInfoObsComponent, {
      size: 'lg',
      windowClass: 'large-modal',
    });
    modalRef.componentInstance.idSynthese = row.id_synthese;
    modalRef.componentInstance.header = true;
    modalRef.componentInstance.useFrom = 'synthese';
  }

  openModalCol($event, modal) {
    this.ngbModal.open(modal);
  }

  openDownloadModal() {
    this.ngbModal.open(SyntheseModalDownloadComponent, {
      size: 'lg',
    });
  }

  getRowClass() {
    return 'row-sm clickable';
  }

  getDate(date) {
    function pad(s) {
      return s < 10 ? '0' + s : s;
    }
    const d = new Date(date);
    return [pad(d.getDate()), pad(d.getMonth() + 1), d.getFullYear()].join('-');
  }

  toggleColumnNames(col) {
    col.checked = !col.checked;
    this.defaultColumns = this.availableColumns.filter((col) => col.checked);
  }

  ngOnChanges(changes) {
    if (changes.inputSyntheseData && changes.inputSyntheseData.currentValue) {
      // reset page 0 when new data appear
      this.table.offset = 0;
    }
  }
}
