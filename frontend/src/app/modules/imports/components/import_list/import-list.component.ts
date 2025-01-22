// @ts-ignore

import { Component, OnInit, TemplateRef, ViewChild } from '@angular/core';
import { Router } from '@angular/router';
import { FormControl } from '@angular/forms';
import { saveAs } from 'file-saver';
import { CommonService } from '@geonature_common/service/common.service';
import { CruvedStoreService } from '@geonature_common/service/cruved-store.service';
import { ImportDataService } from '../../services/data.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { ImportProcessService } from '../import_process/import-process.service';
import { Import } from '../../models/import.model';
import { ConfigService } from '@geonature/services/config.service';
import { CsvExportService } from '../../services/csv-export.service';
import { formatRowCount } from '../../utils/format-row-count';
import { ModalData } from '../../models/modal-data.model';

@Component({
  styleUrls: ['import-list.component.scss'],
  templateUrl: 'import-list.component.html',
})
export class ImportListComponent implements OnInit {
  public history;
  public filteredHistory;
  public empty: boolean = false;
  public selectedRow: Import;
  public interval: any;
  public search = new FormControl();
  public selectDestinationForm = new FormControl();
  public total: number;
  public offset: number;
  public limit: number;

  public sort: string;
  public dir: string;
  public runningImport: Array<number> = [];
  public inErrorImport: Array<number> = [];
  public checkingImport: Array<number> = [];
  private fetchTimeout: any;

  /* Filter value storage */
  private destinationCode: string;
  public searchString: string = '';

  public editModalData:ModalData;
  public deleteModalData:ModalData;
  constructor(
    public _cruvedStore: CruvedStoreService,
    private _ds: ImportDataService,
    private _router: Router,
    private _commonService: CommonService,
    private _modalService: NgbModal,
    private importProcessService: ImportProcessService,
    public _csvExport: CsvExportService,
    public config: ConfigService
  ) {}

  /**
   * Initialize the import list
   */
  ngOnInit() {
    this.onImportList();

    this.fetchTimeout = setTimeout(() => {
      this.updateImports();
    }, 15000);

    // Delay the query to retrieve imports from the database
    this.search.valueChanges.subscribe((value) => {
      setTimeout(() => {
        if (value == this.search.value) {
          this.updateSearchQuery();
        }
      }, 500);
    });
  }

  /**
   * Destroy the timeout
   */
  ngOnDestroy() {
    clearTimeout(this.fetchTimeout);
    this._ds.getImportList({}).subscribe().unsubscribe();
  }

  /**
   * Update the searchString attribute and refresh the import list view
   */
  updateSearchQuery() {
    this.searchString = this.search.value;
    this.resetPage();
  }

  /**
   * Resets the page offset before updating the import list
   */
  resetPage() {
    this.offset = 0;
    this.updateImports();
  }

  /**
   * Refresh the import list based on the page number and value in the filters
   * @param {object} [params={}]
   */
  private onImportList(params: object = {}) {
    let default_params = { page: 1, search: this.searchString };
    default_params = { ...default_params, ...params };
    this._ds.getImportList(default_params, this.selectDestinationForm.value).subscribe((res) => {
      this.history = res['imports'];
      this.getImportsStatus();

      this.filteredHistory = this.history;
      this.empty = res.length == 0;
      this.total = res['count'];
      this.limit = res['limit'];
      this.offset = res['offset'];
      this.fetchTimeout = setTimeout(() => {
        this.updateImports();
      }, 15000);
    });
  }

  /**
   * Return import status
   */
  private getImportsStatus() {
    this.history.forEach((hist) => {
      if (hist.task_id !== null && hist.task_progress !== null) {
        if (hist.task_progress == -1) {
          this.inErrorImport.push(hist.id_import);
        } else if (hist.processed) {
          this.runningImport.push(hist.id_import);
        } else {
          this.checkingImport.push(hist.id_import);
        }
      }
    });
  }

  private resetImportInfos() {
    this.checkingImport = this.inErrorImport = this.runningImport = [];
  }

  private updateImports() {
    let params = { page: this.offset + 1, search: this.searchString };
    if (this.sort) {
      params['sort'] = this.sort;
    }
    if (this.dir) {
      params['sort_dir'] = this.dir;
    }
    this.onImportList(params);
  }

  onFinishImport(data: Import) {
    clearTimeout(this.fetchTimeout);
    this.importProcessService.continueProcess(data);
  }

  downloadSourceFile(row: Import) {
    this._ds.setDestination(row.destination.code);
    this._ds.downloadSourceFile(row.id_import).subscribe((result) => {
      saveAs(result, row.full_file_name);
    });
  }
  /**
   * Downloads a CSV file with the lines that had errors during the import.
   *
   * @param imprt The import that we want to download the errors for.
   */
  downloadFileWithInvalidLine(imprt: Import) {
    this._ds.setDestination(imprt.destination.code);
    this._csvExport.onCSV(imprt.id_import);
  }
  formattedRowCount(row: Import): string {
    return formatRowCount(row);
  }

  openModal(modalTemplate: TemplateRef<any>, actionType: 'edit' | 'delete', row: Import) {
    this.selectedRow = row;
      // Prépare les données de la modale en fonction de l'action
      if (actionType === 'edit') {
        let additionalMessage:string;
        if(!!this.selectedRow.date_end_import) {
          additionalMessage = 'Attention : Vous vous apprêtez à modifier un import terminé. Toute modification entraînera la suppression des données importées.'
        } else {
          additionalMessage = 'Attention : à chaque confirmation de chaque étape de cet import en cours , les données seront écrasées.'
        }
        this.editModalData = {
          title: 'Modification',
          bodyMessage: `Modifier cet import associé au JDD "${this.selectedRow.dataset.dataset_name}" et commencé le ${this.selectedRow.date_create_import}?`,
          additionalMessage: additionalMessage,
          cancelButtonText: 'Annuler',
          confirmButtonText: 'Confirmer',
          confirmButtonColor: 'warn',
          headerDataQa: 'import-modal-edit',
          confirmButtonDataQa: 'modal-edit-validate',
        };  
      } else if (actionType === 'delete') {
        this._ds.setDestination(this.selectedRow.destination.code);
        this.deleteModalData = {
          title: 'Suppression',
          bodyMessage: `Supprimer cet import associé au JDD "${row.dataset.dataset_name}" et commencé le ${row.date_create_import}?`,
          additionalMessage: this.selectedRow.date_end_import
            ? 'Attention : cela supprimera aussi les données importées.'
            : '',
          cancelButtonText: 'Annuler',
          confirmButtonText: 'Supprimer',
          confirmButtonColor: 'warn',
          headerDataQa: 'import-modal-delete',
          confirmButtonDataQa: 'modal-delete-validate',
        };
    }
    this._modalService.open(modalTemplate);
  }
  handleModalAction(event: { confirmed: boolean; actionType: string; data?: any }) {
    if (event.confirmed) {
      if (event.actionType === 'edit') {
        this.onFinishImport(event.data);
      } else if (event.actionType === 'delete') {
        this.onImportList({offset :this.offset, search: this.searchString});
      }
    }
  }

  onSort(e) {
    let sort = e.sorts[0];
    let params = { page: 1, search: this.searchString, sort: sort.prop, sort_dir: sort.dir };
    this.sort = sort.prop;
    this.dir = sort.dir;
    this.onImportList(params);
  }
  setPage(e) {
    let params = { page: e.offset + 1, search: this.searchString };
    if (this.sort) {
      params['sort'] = this.sort;
    }
    if (this.dir) {
      params['sort_dir'] = this.dir;
    }
    this.onImportList(params);
  }
  getTooltip(row, tooltipType) {
    if (!row?.cruved?.U) {
      return "Vous n'avez pas les droits";
    } else if (tooltipType === 'edit') {
      return "Modifier l'import";
    } else {
      return "Supprimer l'import";
    }
  }

  _getStatistics(row) {
    return 'statistics' in row ? row['statistics'] : null;
  }

  getStatisticsTooltip(row) {
    const statistics = this._getStatistics(row);
    return Object.keys(statistics)
      .filter((statkey) => this.getStatisticsLabel(row, statkey) != null) // filter out statistics with no label
      .map((statkey) => this.getStatisticsLabel(row, statkey) + ': ' + statistics[statkey])
      .join('\n');
  }

  hasStatistics(row) {
    const statistics = this._getStatistics(row);
    return Object.keys(statistics).some((key) => {
      return statistics[key];
    });
  }

  /**
   * If exists, returns a label for an import statistic value. If not return the key from the `statistics` object.
   * Labels are defined in the `module.py` in `_imports_.statitics_labels` attribute of the destination module class.
   *
   * @param {any} row - row object use in datable
   * @param {string} statKey - key for a given statistics
   * @return {string} selected label
   */
  getStatisticsLabel(row: any, statKey: string): string {
    if (row.hasOwnProperty('destination')) {
      return row.destination?.statistics_labels.find((stat) => stat.key === statKey)?.value;
    }
    return statKey;
  }

  private generateDataQaAttribute(columnName: string): string {
    return columnName.replace(/\s+/g, '-').toLowerCase();
  }
}
