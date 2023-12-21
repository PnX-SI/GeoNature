import { Component, OnInit, Input } from '@angular/core';
import { Router } from '@angular/router';
import { DataService } from '../../../services/data.service';
import { ImportProcessService } from '../import-process.service';
import { isObservable } from 'rxjs';
import { Import } from '../../../models/import.model';
import { ConfigService } from '@geonature/services/config.service';

@Component({
  selector: 'footer-stepper',
  styleUrls: ['footer-stepper.component.scss'],
  templateUrl: 'footer-stepper.component.html',
})
export class FooterStepperComponent implements OnInit {
  @Input() stepComponent;

  constructor(
    private _router: Router,
    private _ds: DataService,
    private importProcessService: ImportProcessService,
    public config: ConfigService
  ) {}

  ngOnInit() {}

  deleteImport() {
    let importData: Import | null = this.importProcessService.getImportData();
    if (importData) {
      this._ds.deleteImport(importData.id_import).subscribe(() => {
        this.leaveImport();
      });
    } else {
      this.leaveImport();
    }
  }

  saveAndLeaveImport() {
    if (this.stepComponent.onSaveData !== undefined) {
      let ret = this.stepComponent.onSaveData();
      if (isObservable(ret)) {
        ret.subscribe(() => {
          this.leaveImport();
        });
      } else {
        this.leaveImport();
      }
    } else {
      this.leaveImport();
    }
  }

  leaveImport() {
    this.importProcessService.resetImportData();
    this._router.navigate([`${this.config.IMPORT.MODULE_URL}`]);
  }
}
