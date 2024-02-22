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
  public search_string: string = '';
  public sort: string;
  public dir: string;
  public runningImport: Array<number> = [];
  public inErrorImport: Array<number> = [];
  public checkingImport: Array<number> = [];
  private fetchTimeout: any;
  private destCode: string = '';

  constructor(
    public _cruvedStore: CruvedStoreService,
    private _ds: DataService,
    private _router: Router,
    private _commonService: CommonService,
    private modal: NgbModal,
    private importProcessService: ImportProcessService,
    public _csvExport: CsvExportService,
    public config: ConfigService
  ) { }

  ngOnInit() {
    this.onImportList(1);
    this.fetchTimeout = setTimeout(() => {
      this.updateImports();
    }, 15000);
  }

  ngOnDestroy() {
    clearTimeout(this.fetchTimeout);
    this._ds.getImportList({}).subscribe().unsubscribe();
  }

  updateFilter(val: any) {
    const value = val.toString().toLowerCase().trim();
    this.search_string = value;
    this.onImportList(1);
    
    // listes des colonnes selon lesquelles filtrer
  }

  updateDest(destCode: string) {
    this.destCode = destCode;
    this.onImportList(1);
  }

  private onImportList(page) {
    this._ds.getImportList({ page: page, search: this.search_string }, this.destCode).subscribe((res) => {
      this.history = res['imports'];
      this.getImportsStatus();

      this.filteredHistory = this.history;
      this.empty = res.length == 0;
      this.total = res['count'];
      this.limit = res['limit'];
      this.offset = res['offset'];
    });
  }
  private getImportsStatus() {
    this.history.forEach((h) => {
      if (h.task_id !== null && h.task_progress !== null) {
        if (h.task_progress == -1) {
          this.inErrorImport.push(h.id_import);
        } else if (h.processed) {
          this.runningImport.push(h.id_import);
        } else {
          this.checkingImport.push(h.id_import);
        }
      }
    });
  }
  private resetImportInfos() {
    this.checkingImport = this.inErrorImport = this.runningImport = [];
  }
  private updateImports() {
    let params = { page: this.offset + 1, search: this.search_string };
    if (this.sort) {
      params['sort'] = this.sort;
    }
    if (this.dir) {
      params['sort_dir'] = this.dir;
    }
    this._ds.getImportList(params).subscribe((res) => {
      this.history = res['imports'];
      this.checkingImport = [];
      this.getImportsStatus();
      this.filteredHistory = this.history;
      this.fetchTimeout = setTimeout(() => {
        this.updateImports();
      }, 15000);
    });
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
    let params = { page: 1, search: this.search_string, sort: sort.prop, sort_dir: sort.dir };
    this._ds.getImportList(params).subscribe((res) => {
      this.history = res['imports'];
      this.filteredHistory = this.history;
      this.empty = res.length == 0;
      this.total = res['count'];
      this.limit = res['limit'];
      this.offset = res['offset'];
      this.sort = sort.prop;
      this.dir = sort.dir;
    });
  }
  setPage(e) {
    let params = { page: e.offset + 1, search: this.search_string };
    if (this.sort) {
      params['sort'] = this.sort;
    }
    if (this.dir) {
      params['sort_dir'] = this.dir;
    }
    this._ds.getImportList(params).subscribe(
      (res) => {
        this.history = res['imports'];
        this.filteredHistory = this.history;
        this.empty = res.length == 0;
        this.total = res['count'];
        this.limit = res['limit'];
        this.offset = res['offset'];
      },
      (error) => {
        if (error.status === 404) {
          this._commonService.regularToaster('warning', 'Aucun import trouvé');
        }
      }
    );
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
