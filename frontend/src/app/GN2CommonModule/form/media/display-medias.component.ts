import { Component, OnInit, Input, Output, EventEmitter, ViewEncapsulation, SimpleChanges } from '@angular/core';
import { Media } from './media';
import { MediaService } from '@geonature_common/service/media.service'

@Component({
  selector: 'pnx-display-medias',
  templateUrl: './display-medias.component.html',
  styleUrls: ['./media.scss'],
})
export class DisplayMediasComponent implements OnInit {


  public bInitialized:boolean;

  @Input() medias: Array<Media> = []; /** list of medias */

  constructor(
    private _mediaService: MediaService
  ) { }

  ngOnInit() {
    this._mediaService.getNomenclatures().subscribe(() => {this.bInitialized = true; this.initMedias() });
  }

  nomenclature(id_nomenclature) {
    return this._mediaService.getNomenclature(id_nomenclature)
  }

  initMedias() {
    if (!this.bInitialized) return;
    for (const index in this.medias) {
      if (!(this.medias[index] instanceof Media)) {
        this.medias[index] = new Media(this.medias[index]);
      }
    }
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
