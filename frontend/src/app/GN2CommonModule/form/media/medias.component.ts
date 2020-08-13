import { Component, OnInit, Input, Output, EventEmitter, ViewEncapsulation, SimpleChanges } from '@angular/core';
import { Media } from './media';
import { MediaService } from '@geonature_common/service/media.service'

@Component({
  selector: 'pnx-medias',
  templateUrl: './medias.component.html',
  styleUrls: ['./media.scss'],
})
export class MediasComponent implements OnInit {


  @Input() medias: Array<Media> = []; /** list of medias */
  @Output() mediasChange = new EventEmitter<Array<Media>>();

  @Input() schemaDotTable: string;
  @Input() sizeMax: number;

  public bInitialized: boolean;

  constructor(
    private _mediaService: MediaService
  ) { }

  ngOnInit() {
    this._mediaService.getNomenclatures()
    .subscribe(() => {
      this.bInitialized = true;
      this.initMedias()
    });
  };


  initMedias() {
    if (!this.bInitialized) return;
    for (const index in this.medias) {
      if (!(this.medias[index] instanceof Media)) {
        this.medias[index] = new Media(this.medias[index]);
      }
    }
  }

  validOrLoadingMedias() {
    return this._mediaService.validOrLoadingMedias(this.medias);
  }

  onMediaChange() {
    this.mediasChange.emit(this.medias)
  }

  addMedia() {
    this.medias.push(new Media());
    this.mediasChange.emit(this.medias)
  }

  deleteMedia(index) {
    const media = this.medias.splice(index, 1)[0];

    // si l upload est en cours
    if (media.pendingRequest) {
      media.pendingRequest.unsubscribe()
      media.pendingRequest = null;
    }

    // si le media existe déjà en base => route DELETE
    if (media.id_media) {
      this._mediaService.deleteMedia(media.id_media).subscribe((response) => {
        console.log(`delete media ${media.id_media}: ${response}`)
      });
    }
    this.mediasChange.emit(this.medias)

  }

  ngOnChanges(changes: SimpleChanges) {
    for (let propName in changes) {
      let chng = changes[propName];
      let cur = JSON.stringify(chng.currentValue);
      let prev = JSON.stringify(chng.previousValue);

      if (propName === 'medias') {
        this.initMedias()
      }
    }
  }

}
