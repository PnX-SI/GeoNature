import { Component, Input, Output, EventEmitter } from '@angular/core';
import { MatDialog } from '@angular/material/dialog';
import { TranslateService } from '@ngx-translate/core';
import { PublicationsService } from '../../services/publication.service';
import { CommonService } from '@geonature_common/service/common.service';
import { ConfirmationDialog } from '@geonature_common/others/modal-confirmation/confirmation.dialog';
import { Association } from '@geonature/metadataModule/publications/publication.model';

export type AssociationType = 'dataset' | 'acquisition_framework';

@Component({
  selector: 'pnx-publication-disassociate-button',
  templateUrl: './disassociate-publication-button.component.html',
})
export class PublicationDisassociateButtonComponent {
  @Input() publicationId!: number;
  @Input() elementId!: number;
  @Input() elementName!: string;
  @Input() association!: Association;
  @Output() disassociated = new EventEmitter<void>();

  constructor(
    private _dialog: MatDialog,
    private _publicationsListService: PublicationsService,
    private _commonService: CommonService,
    private _translateService: TranslateService
  ) {}

  onDisassociate(): void {
    const elementTypeLabel =
      this.association === 'Dataset'
        ? this._translateService.instant('Dataset')
        : this._translateService.instant('AcquisitionFramework');

    const message = this._translateService.instant('MetaData.Publications.ConfirmDisassociate', {
      publication: this.elementName,
      elementType: elementTypeLabel,
    });

    const dialogRef = this._dialog.open(ConfirmationDialog, {
      width: 'auto',
      position: { top: '5%' },
      data: {
        message: message,
        yesColor: 'primary',
        noColor: 'warn',
      },
    });

    dialogRef.afterClosed().subscribe((result) => {
      if (result) {
        this.performDisassociation();
      }
    });
  }

  private performDisassociation(): void {
    let disassociateObs;

    if (this.association === 'Dataset') {
      disassociateObs = this._publicationsListService.disassociateDatasetFromPublication(
        this.publicationId,
        this.elementId
      );
    } else {
      disassociateObs = this._publicationsListService.disassociateAfFromPublication(
        this.publicationId,
        this.elementId
      );
    }

    disassociateObs.subscribe(
      () => {
        this._commonService.translateToaster(
          'success',
          'MetaData.Publications.Messages.Disassociated'
        );
        this.disassociated.emit();
      },
      (error) => {
        this._commonService.translateToaster(
          'error',
          'MetaData.Publications.Errors.DisassociationFailed'
        );
      }
    );
  }
}
