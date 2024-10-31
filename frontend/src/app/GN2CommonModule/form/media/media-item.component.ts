import { Component, EventEmitter, Input, Output } from '@angular/core';
import { Media } from './media';
import { MediaService } from '@geonature_common/service/media.service';
import { ConfigService } from '@geonature/services/config.service';
import { DomSanitizer, SafeResourceUrl } from '@angular/platform-browser';
import { MatDialog } from '@angular/material/dialog';
import { MediaDiaporamaDialog } from './media-diaporama-dialog.component';
import { EMBEDDABLE_VIDEO_MEDIA_TYPE, MediaType } from './media-type';

@Component({
  selector: 'pnx-media-item',
  templateUrl: './media-item.component.html',
  styleUrls: ['./media-item.component.scss'],
})
export class MediaItem {
  readonly MediaType = MediaType; // Expose to html

  media: Media;
  href: string | false;
  safeEmbedUrl: SafeResourceUrl;
  safeUrl: SafeResourceUrl;
  type: MediaType;

  @Input()
  display: 'icon' | 'medium' | 'default' = 'default';

  @Input()
  set inputMedia(media: any) {
    if (!(media instanceof Media)) {
      this.media = new Media(media);
    } else {
      this.media = media;
    }
    this.href = this.media.href(this._config.API_ENDPOINT, this._config.MEDIA_URL);
    this.safeEmbedUrl = this._sanitizer.bypassSecurityTrustResourceUrl(
      this.ms.embedHref(this.media)
    );
    this.safeUrl = this._sanitizer.bypassSecurityTrustResourceUrl(this.ms.href(this.media));
    this.type = this.ms.typeMedia(this.media);
  }

  @Input()
  diaporamaMedia: Array<any> | null = null;

  constructor(
    private _config: ConfigService,
    private _dialog: MatDialog,
    public ms: MediaService,
    private _sanitizer: DomSanitizer
  ) {}

  isEmbeddableVideoMediaType() {
    return EMBEDDABLE_VIDEO_MEDIA_TYPE.includes(this.type);
  }

  get isIcon(): boolean {
    return this.display == 'icon';
  }
  get isMedium(): boolean {
    return this.display == 'medium';
  }

  get hasDiaporama() {
    return this.diaporamaMedia && this.diaporamaMedia.length > 1;
  }

  openDiaporamaDialog() {
    const index = this.diaporamaMedia.findIndex((media) => media.id_media == this.media.id_media);
    const dialogRef = this._dialog.open(MediaDiaporamaDialog, {
      data: { medias: this.diaporamaMedia, index },
    });
  }
}
