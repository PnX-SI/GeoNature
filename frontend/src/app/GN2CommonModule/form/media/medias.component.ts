import { Component, OnInit, Input, Output, EventEmitter, ViewEncapsulation, SimpleChanges } from '@angular/core';
import { Media } from './media';
import { MediaService } from '@geonature_common/service/media-service'

@Component({
  selector: 'pnx-medias',
  templateUrl: './medias.component.html',
  styleUrls: ['./media.scss'],
})
export class MediasComponent implements OnInit {


  @Input() medias: Array<Media> = []; /** list of medias */
  @Output() mediasChange = new EventEmitter<Array<Media>>();

  @Input() schemaDotTable: string;

  @Output() validFormsChange = new EventEmitter<boolean>();

  constructor(
    private _mediaService: MediaService
  ) { }

  ngOnInit() {
    this.initMedias()
  };

  emitChanges() {
    this.mediasChange.emit(this.medias)
    this.validFormsChange.emit(this.valid())
  }

  valid() {
    // renvoie si tous les médias sont valides et on fini de charger
    return this.medias.every((media) => media.valid() && !media.bLoading)
  }


  initMedias() {
    for (const index in this.medias) {
      if (!(this.medias[index] instanceof Media)) {
        this.medias[index] = new Media(this.medias[index]);
      }
    }
  }

  addMedia() {
    this.medias.push(new Media());
    this.emitChanges()
  }

  deleteMedia(index) {
    const media = this.medias.splice(index, 1)[0];

    // si l upload est en cours
    console.log(media.pendingRequest)
    if(media.pendingRequest) {
      console.log("mediaPendingRequest")
      media.pendingRequest.unsubscribe()
      media.pendingRequest = null;
    }

    // si le media existe déjà en base => route DELETE
    if(media.id_media) {
      this._mediaService.deleteMedia(media.id_media).subscribe((response) => {
        console.log(`delete media ${media.id_media}: ${response}`)
      });
    }
    this.emitChanges();
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
