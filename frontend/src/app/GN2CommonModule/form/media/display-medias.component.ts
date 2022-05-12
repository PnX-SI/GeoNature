import { DomSanitizer } from '@angular/platform-browser';
import {
  Component,
  OnInit,
  Input,
  Output,
  EventEmitter,
  ViewEncapsulation,
  SimpleChanges,
  Inject,
} from '@angular/core';
import { Media } from './media';
import { MediaService } from '@geonature_common/service/media.service';
import { MatDialog } from '@angular/material/dialog';
import { MediaDialog } from './media-dialog.component';

export interface MediaDialogData {
  medias: Array<Media>;
  index: number;
}

@Component({
  selector: 'pnx-display-medias',
  templateUrl: './display-medias.component.html',
  styleUrls: ['./media.scss'],
})
export class DisplayMediasComponent {
  @Input() medias: Array<Media> = [];
  @Input() index: number;
  @Input() display: string;
  @Input() diaporama = false;

  public height: string;
  public thumbnailHeight: number;
  public bInitialized = false;
  public innerHTMLPDF = {};

  constructor(public ms: MediaService, public dialog: MatDialog, public _sanitizer: DomSanitizer) {}

  ngOnInit() {
    this.initMedias();
    this.ms.getNomenclatures().subscribe(() => {
      this.bInitialized = true;
    });
  }

  initMedias() {
    for (const index in this.medias) {
      if (true) {
        if (!(this.medias[index] instanceof Media)) {
          this.medias[index] = new Media(this.medias[index]);
        }
        this.medias[index].safeUrl = this.getSafeUrl(index);
        this.medias[index].safeEmbedUrl = this.getSafeEmbedUrl(index);
      }
    }

    const heights = {
      mini: 50,
      small: 100,
      medium: 200,
    };

    this.height = heights[this.display] ? `${heights[this.display]}px` : '100%';
    this.thumbnailHeight = heights[this.display] || '200';
  }

  openDialog(index) {
    const dialogRef = this.dialog.open(MediaDialog, {
      width: '1000px',
      data: { medias: this.medias, index },
    });
  }

  ngOnChanges(changes: SimpleChanges) {
    for (const propName in changes) {
      if (propName === 'medias') {
        this.initMedias();
      }
    }
  }

  getSafeUrl(index) {
    return this._sanitizer.bypassSecurityTrustResourceUrl(this.medias[index].href());
  }

  getSafeEmbedUrl(index) {
    return this._sanitizer.bypassSecurityTrustResourceUrl(this.ms.embedHref(this.medias[index]));
  }
}
