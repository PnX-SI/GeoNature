import { Component, OnInit, Input, Output, EventEmitter, ViewEncapsulation, SimpleChanges, Inject } from '@angular/core';
import { MatDialog, MatDialogRef, MAT_DIALOG_DATA } from "@angular/material";
import { Media } from './media';
import { MediaService } from '@geonature_common/service/media.service'

export interface MediaDialogData {
  media: Media;
}

@Component({
  selector: 'pnx-media-dialog',
  templateUrl: './media-dialog.component.html',
  styleUrls: ['./media.scss'],
})
export class MediaDialog {

  constructor(
    private _mediaService: MediaService,
    public dialogRef: MatDialogRef<MediaDialog>,
    @Inject(MAT_DIALOG_DATA) public data: MediaDialogData) { }

  onNoClick(): void {
    this.dialogRef.close();
  }

  nomenclature(id_nomenclature) {
    return this._mediaService.getNomenclature(id_nomenclature)
  }

}
