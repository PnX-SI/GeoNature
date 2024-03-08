// @ts-ignore

import { Component, OnInit, ViewChild } from '@angular/core';
import { Router } from '@angular/router';
import { FormControl } from '@angular/forms';
import { saveAs } from 'file-saver';
import { CommonService } from '@geonature_common/service/common.service';
import { CruvedStoreService } from '@geonature_common/service/cruved-store.service';
import { DataService } from '../../services/data.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { ImportProcessService } from '../import_process/import-process.service';
import { Import } from '../../models/import.model';
import { ConfigService } from '@geonature/services/config.service';
import { CsvExportService } from '../../services/csv-export.service';

@Component({
  styleUrls: ['import-list.component.scss'],
  templateUrl: 'import-list.component.html',
})
export class ImportListComponent implements OnInit {
  public history;
  public filteredHistory;
  public empty: boolean = false;
  public deleteOne: Import;
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

  constructor(
    public _cruvedStore: CruvedStoreService,
    private _ds: DataService,
    private _router: Router,
    private _commonService: CommonService,
    private modal: NgbModal,
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

  onViewDataset(row: Import) {
    this._router.navigate([`metadata/dataset_detail/${row.id_dataset}`]);
  }

  downloadSourceFile(row: Import) {
    this._ds.setDestination(row.destination.code);
    this._ds.downloadSourceFile(row.id_import).subscribe((result) => {
      saveAs(result, row.full_file_name);
    });
  }

  openDeleteModal(row: Import, modalDelete) {
    this.deleteOne = row;
    this._ds.setDestination(row.destination.code);
    this.modal.open(modalDelete);
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
    } else if (!row?.dataset?.active) {
      return 'JDD clos';
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
      .map((statkey) => this.getStatisticsLabel(statkey) + ': ' + statistics[statkey])
      .join('\n');
  }

  hasStatistics(row) {
    const statistics = this._getStatistics(row);
    return statistics && Object.keys(statistics).length;
  }

  // TODO: This is a placeholder.
  // It should be handled server side
  getStatisticsLabel(statKey: string): string {
    switch (statKey) {
      case 'taxa_count':
        return 'Nombre de taxon(s)';
      default:
        return statKey;
    }
  }
}
