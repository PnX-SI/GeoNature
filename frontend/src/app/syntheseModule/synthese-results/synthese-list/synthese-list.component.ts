import {
  Component,
  OnInit,
  Input,
  ViewChild,
  HostListener,
  AfterContentChecked,
  OnChanges,
  ChangeDetectorRef
} from '@angular/core';
import { GeoJSON } from 'leaflet';
import { MapListService } from '@geonature_common/map-list/map-list.service';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { SyntheseFormService } from '@geonature_common/form/synthese-form/synthese-form.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { CommonService } from '@geonature_common/service/common.service';
import { AppConfig } from '@geonature_config/app.config';
import { HttpParams } from '@angular/common/http/';
import { DomSanitizer } from '@angular/platform-browser';
import { SyntheseModalDownloadComponent } from './modal-download/modal-download.component';
import { ColumnMode, DatatableComponent } from '@swimlane/ngx-datatable';
import { CruvedStoreService } from '@geonature_common/service/cruved-store.service';
import { SyntheseInfoObsComponent } from '@geonature/shared/syntheseSharedModule/synthese-info-obs/synthese-info-obs.component';


@Component({
  selector: 'pnx-synthese-list',
  templateUrl: 'synthese-list.component.html',
  styleUrls: ['synthese-list.component.scss'],
})
export class SyntheseListComponent implements OnInit, OnChanges, AfterContentChecked {
  public SYNTHESE_CONFIG = AppConfig.SYNTHESE;
  public selectedObs: any;
  public selectObsTaxonInfo: any;
  public selectedObsTaxonDetail: any;
  public previousRow: any;
  public rowNumber: number;
  public queyrStringDownload: HttpParams;
  public inpnMapUrl: string;
  public downloadMessage: string;
  public ColumnMode: ColumnMode;
  //input to resize datatable on searchbar toggle
  @Input() searchBarHidden: boolean;
  @Input() inputSyntheseData: GeoJSON;
  @ViewChild('table', { static: true }) table: DatatableComponent;
  private _latestWidth: number;
  constructor(
    public mapListService: MapListService,
    private _ds: SyntheseDataService,
    public ngbModal: NgbModal,
    private _commonService: CommonService,
    private _fs: SyntheseFormService,
    public sanitizer: DomSanitizer,
    public ref: ChangeDetectorRef,
    public _cruvedStore: CruvedStoreService
  ) {}

  ngOnInit() {
    // get wiewport height to set the number of rows in the tabl
    const h = document.documentElement.clientHeight;
    this.rowNumber = Math.trunc(h / 37);

    // On map click, select on the list a change the page
    this.mapListService.onMapClik$.subscribe((id) => {
      this.mapListService.tableData.map((e) => {
        if (e.selected && !id.includes(e.id)) {
          e.selected = false;
        } else if (id.includes(e.id)) {
          e.selected = true;
        }
      });
      let observations = this.mapListService.tableData.filter((e) => {
        return id.includes(e.id);
      });
      this.mapListService.tableData.sort((a, b) => {
        return b.selected - a.selected;
      });
      this.mapListService.tableData = [...this.mapListService.tableData];
      this.mapListService.selectedRow = observations;
      const page = Math.trunc(
        this.mapListService.tableData.findIndex((e) => {
          return e.id === id[0];
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

  getQueryString(): HttpParams {
    const formatedParams = this._fs.formatParams();
    return this._ds.buildQueryUrl(formatedParams);
  }

  openInfoModal(row) {
    row.id_synthese = row.id;
    const modalRef = this.ngbModal.open(SyntheseInfoObsComponent, {
      size: 'lg',
      windowClass: 'large-modal',
    });
    modalRef.componentInstance.idSynthese = row.id_synthese;
    modalRef.componentInstance.uuidSynthese = row.unique_id_sinp;
    modalRef.componentInstance.header = true;
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

  ngOnChanges(changes) {
    if (changes.inputSyntheseData && changes.inputSyntheseData.currentValue) {
      // reset page 0 when new data appear
      this.table.offset = 0;
    }
  }
}
