import { Component, OnInit, Input } from '@angular/core';
import { Media } from './media';
import { MediaService } from '@geonature_common/service/media.service'
import { MatDialog } from "@angular/material";
import {MediaDialog} from './media-dialog.component';


@Component({
  selector: 'pnx-display-media',
  templateUrl: './display-media.component.html',
  styleUrls: ['./media.scss'],
})
export class DisplayMediaComponent implements OnInit {

  @Input() media: Media;
  @Input() display: string = '';

  constructor(
    private _mediaService: MediaService,
    public dialog: MatDialog,
  ) { }

  ngOnInit() {
  }

  nomenclature(id_nomenclature) {
    return this._mediaService.getNomenclature(id_nomenclature)
  }

  openDialog() {
    const dialogRef = this.dialog.open(MediaDialog, {
      width: '800px',
      data: { media: this.media },
    });
  }

}
