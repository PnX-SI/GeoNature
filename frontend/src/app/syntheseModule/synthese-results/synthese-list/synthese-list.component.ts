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
import { HttpParams } from '@angular/common/http/src/params';
import { DomSanitizer } from '@angular/platform-browser';
import { SyntheseModalDownloadComponent } from './modal-download/modal-download.component';
import { DatatableComponent } from '@swimlane/ngx-datatable';
import { ModalInfoObsComponent } from './modal-info-obs/modal-info-obs.component';
import { CruvedStoreService } from '../../../services/cruved-store.service';

@Component({
  selector: 'pnx-synthese-list',
  templateUrl: 'synthese-list.component.html',
  styleUrls: ['synthese-list.component.scss']
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
  //input to resize datatable on searchbar toggle
  @Input() searchBarHidden: boolean;
  @Input() inputSyntheseData: GeoJSON;
  @ViewChild('table') table: DatatableComponent;
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
    this.mapListService.onMapClik$.subscribe(id => {
      this.mapListService.selectedRow = []; // clear selected list

      const integerId = parseInt(id);
      let i;
      for (i = 0; i < this.mapListService.tableData.length; i++) {
        if (this.mapListService.tableData[i]['id'] === integerId) {
          this.mapListService.selectedRow.push(this.mapListService.tableData[i]);
          break;
        }
      }
      const page = Math.trunc(i / this.rowNumber);
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

  dateComparator(a: Date, b: Date) {
    if (new Date(a) < new Date(b)) return -1;
    if (new Date(a) > new Date(b)) return 1;
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
    const modalRef = this.ngbModal.open(ModalInfoObsComponent, {
      size: 'lg',
      windowClass: 'large-modal'
    });
    modalRef.componentInstance.oneObsSynthese = row;
  }

  openDownloadModal() {
    const modalRef = this.ngbModal.open(SyntheseModalDownloadComponent, {
      size: 'lg'
    });

    let queryString = this.getQueryString();
    // if the search form has not been touched, download the last 100 obs
    if (this._fs.searchForm.pristine) {
      queryString = queryString.set('limit', AppConfig.SYNTHESE.NB_LAST_OBS.toString());
    }
    modalRef.componentInstance.queryString = queryString;
  }

  getRowClass() {
    return 'row-sm clickable';
  }

  ngOnChanges(changes) {
    if (changes.inputSyntheseData && changes.inputSyntheseData.currentValue) {
      // reset page 0 when new data appear
      this.table.offset = 0;
    }
  }
}
