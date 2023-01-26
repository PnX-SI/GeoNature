import { MapListService } from '@geonature_common/map-list/map-list.service';
import { TranslateService } from '@ngx-translate/core';
import {
  Component,
  OnInit,
  Input,
  Output,
  ViewChild,
  HostListener,
  AfterContentChecked,
  OnChanges,
  ChangeDetectorRef,
  EventEmitter,
} from '@angular/core';
import { MapService } from '@geonature_common/map/map.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { ModuleConfig } from '../../module.config';
import { DomSanitizer } from '@angular/platform-browser';
import { DatatableComponent } from '@swimlane/ngx-datatable';
import { ValidationModalInfoObsComponent } from '../validation-modal-info-obs/validation-modal-info-obs.component';
import { SyntheseFormService } from '@geonature_common/form/synthese-form/synthese-form.service';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { find, isEmpty, get, findIndex } from 'lodash';
import { ConfigService } from '@geonature/services/config.service';

@Component({
  selector: 'pnx-validation-synthese-list',
  templateUrl: 'validation-synthese-list.component.html',
  styleUrls: ['validation-synthese-list.component.scss'],
})
export class ValidationSyntheseListComponent implements OnInit, OnChanges, AfterContentChecked {
  public VALIDATION_CONFIG = ModuleConfig;
  public oneSyntheseObs: any;
  selectedObs: Array<number> = []; // list of id_synthese values for selected rows
  selectedIndex: Array<number> = [];
  selectedPages = [];
  coordinates_list = []; // list of coordinates for selected rows
  marker: MediaTrackSupportedConstraints;
  public rowNumber: number;
  private _latestWidth: number;
  public id_same_coordinates = []; // list of observation ids having same geographic coordinates
  public modif_text = 'Attention données modifiées depuis la dernière validation';
  public npage;

  @Input() inputSyntheseData: Array<any>;
  @Input() validationStatus: Array<any>;
  @ViewChild('table') table: DatatableComponent;
  @Output() pageChange: EventEmitter<number>;
  @Output() displayAll = new EventEmitter<any>();
  @Input() idSynthese: any;
  public validationStatusAsDict: any;
  public datatable_column_list: Array<any>;
  public messages: any;
  public alertActivate: boolean;
  public pinActivate: boolean;

  constructor(
    public mapListService: MapListService,
    private translate: TranslateService,
    private _ds: SyntheseDataService,
    public ngbModal: NgbModal,
    public sanitizer: DomSanitizer,
    public ref: ChangeDetectorRef,
    private _ms: MapService,
    public formService: SyntheseFormService,
    public config: ConfigService
  ) {}

  ngOnInit() {
    this.alertActivate =
      this.config.SYNTHESE.ALERT_MODULES &&
      this.config.SYNTHESE.ALERT_MODULES.includes('VALIDATION');
    this.pinActivate =
      this.config.SYNTHESE.PIN_MODULES && this.config.SYNTHESE.PIN_MODULES.includes('VALIDATION');

    // get wiewport height to set the number of rows in the tabl
    const h = document.documentElement.clientHeight;
    this.rowNumber = Math.trunc(h / 37);

    // this.group = new FeatureGroup();
    this.onMapClick();
    this.onTableClick();
    this.npage = 1;
    this.messages = {
      emptyMessage: this.idSynthese
        ? this.translate.instant('Validation.noIdFound')
        : this.translate.instant('Validation.noData'),
    };
  }

  onMapClick() {
    this.mapListService.onMapClik$.subscribe((id) => {
      this.mapListService.selectedRow = [];
      const integerId = parseInt(id);
      let i;
      for (i = 0; i < this.mapListService.tableData.length; i++) {
        if (this.mapListService.tableData[i]['id_synthese'] === integerId) {
          this.mapListService.selectedRow.push(this.mapListService.tableData[i]);
          break;
        }
      }
      const page = Math.trunc(i / this.rowNumber);
      this.table.offset = page;
    });
  }

  onTableClick() {
    this.setSelectedObs();
    this.mapListService.onTableClick$.subscribe((id) => {
      if (typeof id == 'number') {
        const selectedLayer = this.mapListService.layerDict[id];
        selectedLayer.bringToFront();
      }
      this.setSelectedObs();
      this.setOriginStyleToAll();
      this.setSelectedSyleToSelectedRows();
    });
  }

  ngAfterContentChecked() {
    if (this.table && this.table.element.clientWidth !== this._latestWidth) {
      this._latestWidth = this.table.element.clientWidth;
      this.table.recalculate();
    }
  }

  handlePageChange(event): void {
    this.npage = event.page;
  }

  setOriginStyleToAll() {
    for (let obs in this.mapListService.layerDict) {
      this.mapListService.layerDict[obs].setStyle(
        this.VALIDATION_CONFIG.MAP_POINT_STYLE.originStyle
      );
    }
  }

  setSelectedSyleToSelectedRows() {
    for (let obs of this.selectedObs) {
      this.mapListService.layerDict[obs].setStyle(
        this.VALIDATION_CONFIG.MAP_POINT_STYLE.selectedStyle
      );
    }
  }

  selectAll() {
    this.mapListService.selectedRow = [...this.mapListService.tableData];
    this.setSelectedObs();
    this.viewFitList(this.selectedObs);
    this.setSelectedSyleToSelectedRows();
  }

  deselectAll() {
    this.mapListService.selectedRow = [];
    this.setSelectedObs();
    if (this.mapListService.selectedRow.length === 0) {
      this.setOriginStyleToAll();
    }
  }
  toggleSelection(element) {
    if (element.target.checked) {
      this.selectAll();
    } else {
      this.deselectAll();
    }
  }
  onActivate(event) {
    if (event.type == 'checkbox' || event.type == 'click') {
      this.setSelectedObs();
      this.viewFitList(this.selectedObs);
      if (this.mapListService.selectedRow.length === 0) {
        this.setOriginStyleToAll();
      }
    }
  }

  viewFitList(id_observations) {
    if (id_observations.length) {
      this.mapListService.zoomOnSeveralSelectedLayers(this._ms.map, id_observations);
    }
  }

  setSelectedObs() {
    // array of id_sythese values of selected observations
    this.selectedObs = [];
    this.selectedIndex = [];
    this.selectedPages = [];
    if (this.mapListService.selectedRow.length === 0) {
      this.selectedObs = [];
    } else {
      for (let obs in this.mapListService.selectedRow) {
        this.selectedObs.push(this.mapListService.selectedRow[obs]['id_synthese']);
      }
    }

    for (let obs of this.selectedObs) {
      // find position of selected observations in the ngxtable from id_synthese of selected observations
      this.selectedIndex.push(
        this.mapListService.tableData.findIndex((i) => i.id_synthese === obs)
      );
    }

    // find page from an ngxindex
    for (let ind of this.selectedIndex) {
      let PageIndex = (ind + 1) / this.table._limit;
      this.selectedPages.push(Math.ceil(PageIndex));
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

  getRowClass() {
    return 'row-sm clickable';
  }

  ngOnChanges(changes) {
    if (changes.inputSyntheseData && changes.inputSyntheseData.currentValue) {
      // reset page 0 when new data appear
      if (this.table) {
        this.table.offset = 0;
      }
      this.openInfoModal(
        this.inputSyntheseData.filter((i) => i.id_synthese == this?.idSynthese)[0]
      );
    }
    this.deselectAll();
  }

  openInfoModal(row) {
    if (!row) return;
    this.oneSyntheseObs = row;
    const modalRef = this.ngbModal.open(ValidationModalInfoObsComponent, {
      size: 'lg',
      windowClass: 'large-modal',
    });

    modalRef.componentInstance.id_synthese = row.id_synthese;
    modalRef.componentInstance.uuidSynthese = row.unique_id_sinp;
    modalRef.componentInstance.validationStatus = this.validationStatus;
    modalRef.componentInstance.currentValidationStatus = row.nomenclature_valid_status;
    modalRef.componentInstance.mapListService = this.mapListService;
    modalRef.componentInstance.modifiedStatus.subscribe((modifiedStatus) => {
      for (let obs in this.mapListService.tableData) {
        if (this.mapListService.tableData[obs].id_synthese == modifiedStatus.id_synthese) {
          this.mapListService.tableData[obs].cd_nomenclature_validation_status =
            modifiedStatus.new_status;
          this.mapListService.tableData[obs].validation_auto = '';
        }
      }
    });
    modalRef.componentInstance.onCloseModal.subscribe(() => {
      // to refresh mapListService table UI
      this.updateReports();
    });
    modalRef.componentInstance.valDate.subscribe((data) => {
      for (let obs in this.mapListService.selectedRow) {
        this.mapListService.selectedRow[obs]['validation_date'] = data;
      }
      this.mapListService.selectedRow = [...this.mapListService.selectedRow];
    });
  }

  /**
   * Find selected obs row from table list by id synthese, and call reports to update.
   * This call il required to get report_id value required to use DELETE route
   */
  updateReports() {
    if (this.oneSyntheseObs) {
      const rowIndex = findIndex(this.mapListService.tableData, [
        'id_synthese',
        this.oneSyntheseObs.id_synthese,
      ]);
      // get all reports
      const params = `idSynthese=${this.oneSyntheseObs.id_synthese}`;
      this._ds.getReports(params).subscribe((response) => {
        // search alert in table to update and refresh UI
        this.mapListService.tableData[rowIndex].reports = response;
      });
    }
  }

  /**
   * Catch report by type from selected obs reports list
   * @param row from selected table line
   * @param type from report type
   * @param attribute attribute to match
   * @returns object from TReport model
   */
  findReportInfo(row, type, attribute) {
    const reportItem = find(row.reports, ['report_type.type', type]);
    if (attribute && !isEmpty(reportItem)) {
      // search a value if we search a value and not complet report
      return get(reportItem, `${attribute}`);
    }
    // search if exists
    return reportItem;
  }
}
