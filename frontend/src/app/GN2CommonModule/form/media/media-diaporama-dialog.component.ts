import { Component, HostListener, Inject } from '@angular/core';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { Media } from './media';
import { MediaService } from '@geonature_common/service/media.service';
import { ConfigService } from '@geonature/services/config.service';

export interface MediaDiaporamaDialogData {
  medias: Array<Media>;
  index: number;
}

@Component({
  selector: 'pnx-media-diaporama-dialog',
  templateUrl: './media-diaporama-dialog.component.html',
  styleUrls: ['./media.scss'],
})
export class MediaDiaporamaDialog {
  constructor(
    public ms: MediaService,
    public dialogRef: MatDialogRef<MediaDiaporamaDialog>,
    @Inject(MAT_DIALOG_DATA) public data: MediaDiaporamaDialogData,
    public config: ConfigService
  ) {}

  public currentMedia: Media;
  public medias;
  public curIndex;
  public bDisplay = true;

  ngOnInit() {
    this.curIndex = this.data.index;
    this.medias = this.data.medias;
    this.currentMedia = this.medias[this.curIndex];
  }

  @HostListener('window:keydown', ['$event'])
  handleKeyDown(event: KeyboardEvent) {
    switch (event.key) {
      case 'ArrowLeft':
        this.changeMedia(-1);
        break;
      case 'ArrowRight':
        this.changeMedia(1);
        break;
      default:
        break;
    }
  }

  onNoClick(): void {
    this.dialogRef.close();
  }

  changeMedia(step) {
    this.bDisplay = false;
    setTimeout(() => {
      this.curIndex =
        (((this.curIndex + step) % this.medias.length) + this.medias.length) % this.medias.length;
      this.currentMedia = this.medias[this.curIndex];
      this.bDisplay = true;
    }, 250);
  }
}
