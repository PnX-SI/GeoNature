import { Component, OnInit, ViewChild } from '@angular/core';
import { Router, ActivatedRoute } from '@angular/router';
import { ImportProcessService } from '../import-process.service';
import { DataService } from '../../../services/data.service';
import { CommonService } from '@geonature_common/service/common.service';
import { Step } from '../../../models/enums.model';
import { Import, ImportPreview } from '../../../models/import.model';
import { ConfigService } from '@geonature/services/config.service';
import { CsvExportService } from '../../../services/csv-export.service';

@Component({
  selector: 'import-step',
  styleUrls: ['import-step.component.scss'],
  templateUrl: 'import-step.component.html',
})
export class ImportStepComponent implements OnInit {
  public step: Step;
  public importData: Import;
  // public isCollapsed = false;
  // public idImport: any;
  // importDataRes: any;
  // total_columns: any;
  public previewData: ImportPreview;
  public spinner: boolean = false;
  // public nbLignes: string = "X";
  public errorCount: number;
  public warningCount: number;
  public invalidRowCount: number;
  public nValidData: number;
  public tableReady: boolean = false;
  public progress: number = 0;
  public importRunning: boolean = false;
  public importDone: boolean = false;
  public progressBar: boolean = false;
  public errorStatus: string = '';
  private timeout: number = 100;
  private runningTimeout: any;

  @ViewChild('modalRedir') modalRedir: any;

  constructor(
    private importProcessService: ImportProcessService,
    private _router: Router,
    private _route: ActivatedRoute,
    private _ds: DataService,
    private _commonService: CommonService,
    public _csvExport: CsvExportService,
    public config: ConfigService
  ) {}

  ngOnInit() {
    this.step = this._route.snapshot.data.step;
    this.importData = this.importProcessService.getImportData();
    // TODO : parallel requests, spinner
    if (this.importData.task_progress !== null && this.importData.task_id !== null) {
      if (this.importData.processed) {
        this.importDone = false;
        this.importRunning = true;
        this.checkImportState(this.importData);
      } else {
        this.progressBar = true;
        this.verifyChecksDone();
      }
    } else if (this.importData.processed) {
      this.setImportData();
    }
  }
  ngOnDestroy() {
    if (this.runningTimeout !== undefined) {
      clearTimeout(this.runningTimeout);
    }
  }
  setImportData() {
    this._ds.getImportErrors(this.importData.id_import).subscribe(
      (importErrors) => {
        this.errorCount = importErrors.filter((error) => error.type.level == 'ERROR').length;
        this.warningCount = importErrors.filter((error) => error.type.level == 'WARNING').length;
      },
      (err) => {
        this.spinner = false;
      }
    );
    this._ds.getValidData(this.importData.id_import).subscribe((res) => {
      this.spinner = false;
      this.previewData = res;
      this.nValidData = res.entities.map((e) => e.n_valid_data).reduce((a, b) => a + b);
      this.tableReady = true;
    });
  }

  openReportSheet() {
    const url = new URL(window.location.href);
    url.hash = this._router.serializeUrl(
      this._router.createUrlTree([
        'import',
        this.importData.destination.code,
        this.importData.id_import,
        'report',
      ])
    );
    window.open(url.href, '_blank');
  }

  onPreviousStep() {
    this.importProcessService.navigateToPreviousStep(this.step);
  }
  isNextStepAvailable() {
    return true;
  }
  verifyChecksDone() {
    this._ds
      .getOneImport(this.importData.id_import)
      .pipe()
      .subscribe((importData: Import) => {
        if (importData.task_progress === null && importData.task_id === null) {
          this.progressBar = false;
          this.importProcessService.setImportData(importData);
          this.importData = importData;
          this.progress = 0;
          this.timeout = 100;
          this.setImportData();
        } else if (importData.task_progress === -1) {
          this.timeout = 100;
          this.progress = 0;
          this.errorStatus = 'check';
          this.progressBar = false;
        } else {
          this.progress = 100 * importData.task_progress;
          if (this.timeout < 1000) {
            this.timeout += 100;
          }
          this.runningTimeout = setTimeout(() => this.verifyChecksDone(), this.timeout);
        }
      });
  }
  performChecks() {
    this._ds.prepareImport(this.importData.id_import).subscribe(() => {
      this.progressBar = true;
      this.verifyChecksDone();
    });
  }
  checkImportState(data) {
    this._ds
      .getOneImport(this.importData.id_import)
      .pipe()
      .subscribe((importData: Import) => {
        if (importData.task_progress === null && importData.task_id === null) {
          this.importRunning = false;
          this.importProcessService.setImportData(importData);
          this.importDone = true;
          this._commonService.regularToaster('info', 'Données importées !');
          this._router.navigate([
            this.config.IMPORT.MODULE_URL,
            this.importData.destination.code,
            this.importData.id_import,
            'report',
          ]);
        } else if (importData.task_progress === -1) {
          this.errorStatus = 'import';
          this.importRunning = false;
        } else {
          this.progress = 100 * importData.task_progress;
          if (this.timeout < 1000) {
            this.timeout += 100;
          }
          this.runningTimeout = setTimeout(() => this.checkImportState(data), this.timeout);
        }
      });
  }
  onImport() {
    this._ds.finalizeImport(this.importData.id_import).subscribe(
      (importData) => {
        this.importRunning = true;
        this.checkImportState(importData);
      },
      (error) => {
        this.importRunning = false;
      }
    );
  }

  onRedirect() {
    this._router.navigate([this.config.IMPORT.MODULE_URL]);
  }
}
