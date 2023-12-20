import { Component, OnInit, OnDestroy } from '@angular/core';
import { Router, ActivatedRoute } from '@angular/router';
import { ImportProcessService } from '../import_process/import-process.service';

import { Import, ImportError } from '../../models/import.model';
import { DataService } from '../../services/data.service';

@Component({
  selector: 'pnx-import-errors',
  templateUrl: 'import_errors.component.html',
  styleUrls: ['import_errors.component.scss'],
})
export class ImportErrorsComponent implements OnInit {
  public importData: Import;
  public importErrors: Array<ImportError> = null;
  public importWarnings: Array<ImportError> = null;

  constructor(
    private _router: Router,
    private _route: ActivatedRoute,
    private _ds: DataService
  ) {
    _router.routeReuseStrategy.shouldReuseRoute = () => false; // reset component on importId change
  }

  ngOnInit() {
    this.importData = this._route.snapshot.data.importData;
    this._ds.getImportErrors(this.importData.id_import).subscribe((errors) => {
      this.importErrors = errors.filter((err) => {
        return err.type.level === 'ERROR';
      });
      this.importWarnings = errors.filter((err) => {
        return err.type.level === 'WARNING';
      });
    });
  }
}
