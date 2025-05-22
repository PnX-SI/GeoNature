import { Component, Input } from '@angular/core';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { MetadataService } from '../services/metadata.service';
import { ConfirmationDialog } from '@geonature_common/others/modal-confirmation/confirmation.dialog';
import { MatDialog } from '@angular/material/dialog';
import { Router } from '@angular/router';
import { CommonService } from '@geonature_common/service/common.service';

enum ButtonType {
  Toolbar = 'Toolbar',
  Floating = 'Floating',
}

const METADATA_URL = '/metadata';
@Component({
  selector: 'gn-button-delete-af',
  templateUrl: './button-delete-af.component.html',
  styleUrls: ['./button-delete-af.component.scss'],
})
export class ButtonDeleteAfComponent {
  readonly ButtonType = ButtonType;

  @Input()
  acquisitionFramework: any;

  @Input()
  redirectionUrl: string = METADATA_URL;

  @Input()
  buttonType: ButtonType = ButtonType.Toolbar;

  constructor(
    private _dfs: DataFormService,
    private _mds: MetadataService,
    private _dialog: MatDialog,
    private _router: Router,
    private _commonService: CommonService
  ) {}

  deleteAcquisitionFramework() {
    const dialogRef = this._dialog.open(ConfirmationDialog, {
      width: 'auto',
      position: { top: '5%' },
      data: {
        message: "Voulez-vous supprimer ce cadre d'acquisition ?",
        yesColor: 'primary',
        noColor: 'warn',
      },
    });
    dialogRef.afterClosed().subscribe((result) => {
      if (result) {
        this._dfs.deleteAf(this.acquisitionFramework.id_acquisition_framework).subscribe((res) => {
          this._mds.getMetadata();
          if (this.redirectionUrl) {
            this._router.navigate([this.redirectionUrl]);
          }
          this._commonService.translateToaster('success', 'MetaData.Messages.AFDeleted');
        });
      }
    });
  }

  get disabled() {
    return !this.acquisitionFramework.cruved.D;
  }
}
