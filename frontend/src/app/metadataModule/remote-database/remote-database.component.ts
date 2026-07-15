import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';
import { UntypedFormGroup } from '@angular/forms';
import { Observable } from 'rxjs';
import { MatDialog } from '@angular/material/dialog';

import { RemoteDatabaseFormDialogComponent } from './remote-database-form-dialog';
import { MetadataDataService } from '../services/metadata-data.service';
import { CommonService } from '@geonature_common/service/common.service';

@Component({
  selector: 'pnx-metadata-remote-database',
  templateUrl: './remote-database.component.html',
  styleUrls: ['./remote-database.component.scss'],
})
export class RemoteDatabaseComponent implements OnInit {
  @Input() formControl: UntypedFormGroup;
  @Input() remoteDatabases: Observable<any[]>;
  @Output() remoteDatabaseRefreshed = new EventEmitter<Observable<any[]>>();

  constructor(
    private dialog: MatDialog,
    private metadataDataS: MetadataDataService,
    private commonService: CommonService
  ) {}

  ngOnInit() {
    if (!this.remoteDatabases) {
      this.remoteDatabases = this.metadataDataS.getRemoteDatabases();
    }
  }

  openRemoteDatabaseDialog(): void {
    const dialogRef = this.dialog.open(RemoteDatabaseFormDialogComponent, {
      width: '600px',
      disableClose: false,
    });

    dialogRef.afterClosed().subscribe((result) => {
      if (result) {
        this.remoteDatabases = this.metadataDataS.getRemoteDatabases();
        this.remoteDatabaseRefreshed.emit(this.remoteDatabases);
        this.formControl.patchValue({ id_remote_database: result.id_remote_database });
        this.commonService.translateToaster('success', 'MetaData.RemoteDatabase.CreatedSuccess');
      }
    });
  }
}
