import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';
import { UntypedFormGroup } from '@angular/forms';
import { Observable } from 'rxjs';
import { MatDialog } from '@angular/material/dialog';

import { ProductionDatabaseFormDialogComponent } from './production-database-form-dialog';
import { MetadataDataService } from '../services/metadata-data.service';
import { CommonService } from '@geonature_common/service/common.service';
import { ModuleService } from '@geonature/services/module.service';

@Component({
  selector: 'pnx-metadata-production-database',
  templateUrl: './production-database.component.html',
  styleUrls: ['./production-database.component.scss'],
})
export class ProductionDatabaseComponent implements OnInit {
  @Input() parentForm: UntypedFormGroup;
  @Input() productionDatabases: Observable<any[]>;
  @Output() productionDatabaseRefreshed = new EventEmitter<Observable<any[]>>();

  public canAdd: boolean = false;
  constructor(
    private dialog: MatDialog,
    private metadataDataS: MetadataDataService,
    private commonService: CommonService,
    private _moduleService: ModuleService
  ) {}

  ngOnInit() {
    if (!this.productionDatabases) {
      this.productionDatabases = this.metadataDataS.getProductionDatabases();
    }
    this.canAdd =
      this._moduleService.currentModule?.module_objects?.PRODUCTION_DATABASE?.cruved.C > 0;
  }

  openProductionDatabaseDialog(): void {
    if (!this.canAdd) {
      return;
    }
    const dialogRef = this.dialog.open(ProductionDatabaseFormDialogComponent, {
      width: '600px',
      disableClose: false,
      data: { productionDatabases: this.productionDatabases },
    });

    dialogRef.afterClosed().subscribe((result) => {
      if (result) {
        // Get updated production databases after adding one
        this.productionDatabases = this.metadataDataS.getProductionDatabases();
        this.productionDatabaseRefreshed.emit(this.productionDatabases);
        this.parentForm.patchValue({ id_production_database: result.id_production_database });
        this.commonService.translateToaster(
          'success',
          'MetaData.ProductionDatabase.CreatedSuccess'
        );
      }
    });
  }
}
