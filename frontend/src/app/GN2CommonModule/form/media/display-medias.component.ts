import { Component, OnInit, Input, Output, EventEmitter, ViewEncapsulation, SimpleChanges } from '@angular/core';
import { Media } from './media';
import { MediaService } from '@geonature_common/service/media.service'

@Component({
  selector: 'pnx-dispay-medias',
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
    this._mediaService.getNomenclatures().subscribe(() => this.bInitialized = true);
  }
}
