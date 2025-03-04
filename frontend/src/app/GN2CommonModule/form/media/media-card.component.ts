import { Component, Input } from '@angular/core';
import { Media } from './media';
import { MediaService } from '@geonature_common/service/media.service';
import { ConfigService } from '@geonature/services/config.service';
import { DomSanitizer, SafeResourceUrl } from '@angular/platform-browser';
import { MediaType } from './media-type';

@Component({
  selector: 'pnx-media-card',
  templateUrl: './media-card.component.html',
  styleUrls: ['./media-card.component.scss'],
})
export class MediaCard {
  media: Media;
  href: string | false;
  type: MediaType;

  @Input()
  set inputMedia(media: any) {
    if (!(media instanceof Media)) {
      this.media = new Media(media);
    } else {
      this.media = media;
    }
    this.href = this.media.href(this.config.API_ENDPOINT, this.config.MEDIA_URL);
    this.type = this.ms.typeMedia(this.media);
  }

  @Input()
  diaporamaMedia: Array<any> | null = null;

  constructor(
    public ms: MediaService,
    public config: ConfigService,
    public _sanitizer: DomSanitizer
  ) {}
}
