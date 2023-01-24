import {
  Component,
  Inject,
} from '@angular/core';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { Media } from './media';
import { MediaService } from '@geonature_common/service/media.service';

export interface MediaDialogData {
  medias: Array<Media>;
  index: number;
}

@Component({
  selector: 'pnx-media-dialog',
  templateUrl: './media-dialog.component.html',
  styleUrls: ['./media.scss'],
})
export class MediaDialog {
  constructor(
    public ms: MediaService,
    public dialogRef: MatDialogRef<MediaDialog>,
    @Inject(MAT_DIALOG_DATA) public data: MediaDialogData
  ) {}

  public media: Media;
  public medias;
  public curIndex;
  public bDisplay = true;

  ngOnInit() {
    this.curIndex = this.data.index;
    this.medias = this.data.medias;
    this.media = this.medias[this.curIndex];
  }

  onNoClick(): void {
    this.dialogRef.close();
  }

  changeMedia(step) {
    this.bDisplay = false;
    setTimeout(() => {
      this.curIndex =
        (((this.curIndex + step) % this.medias.length) + this.medias.length) % this.medias.length;
      this.media = this.medias[this.curIndex];
      this.bDisplay = true;
    }, 250);
  }
}
