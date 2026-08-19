import { Component, Input } from '@angular/core';
import { MatDialog } from '@angular/material/dialog';
import { TranslateService } from '@ngx-translate/core';
import { PublicationsService } from '../../services/publication.service';
import { CommonService } from '@geonature_common/service/common.service';
import { Publication } from '../publication.model';
import { ConfirmationDialog } from '@geonature_common/others/modal-confirmation/confirmation.dialog';

@Component({
  selector: 'pnx-publication-delete-button',
  templateUrl: './publication-delete-button.component.html',
})
export class PublicationDeleteButtonComponent {
  @Input() publication: Publication;

  constructor(
    private _dialog: MatDialog,
    private _publicationsService: PublicationsService,
    private _commonService: CommonService,
    private _translateService: TranslateService
  ) {}

  isDeletable(): boolean {
    if (
      !this.publication?.cruved.D ||
      (this.publication.acquisition_frameworks &&
        this.publication.acquisition_frameworks.length > 0) ||
      (this.publication.datasets && this.publication.datasets.length > 0)
    ) {
      return false;
    }
    return true;
  }

  getDeleteTooltip(): string {
    if (!this.isDeletable()) {
      if (!this.publication?.cruved.D) {
        return this._translateService.instant('Errors.NotAllowed');
      }
      let tooltip = this._translateService.instant(
        'MetaData.Publications.Errors.DeletionImpossible'
      );
      if (this.publication?.datasets && this.publication.datasets.length > 0) {
        return (
          tooltip +
          ' ' +
          this._translateService.instant('MetaData.Publications.Errors.LinkedDatasets')
        );
      }
      if (
        this.publication?.acquisition_frameworks &&
        this.publication.acquisition_frameworks.length > 0
      ) {
        return (
          tooltip +
          ' ' +
          this._translateService.instant('MetaData.Publications.Errors.LinkedAcquisitionFrameworks')
        );
      }
    }
    return this._translateService.instant('Actions.Delete');
  }

  onDeletePublication() {
    const dialogRef = this._dialog.open(ConfirmationDialog, {
      width: 'auto',
      position: { top: '5%' },
      data: {
        message: this._translateService.instant('MetaData.Publications.ConfirmDelete'),
        yesColor: 'primary',
        noColor: 'warn',
      },
    });

    dialogRef.afterClosed().subscribe((result) => {
      if (result) {
        this._publicationsService
          .deletePublication(this.publication.id_publication)
          .subscribe(() => {
            this._commonService.translateToaster(
              'success',
              'MetaData.Publications.Messages.Deleted'
            );
          });
      }
    });
  }
}
