import { Component, OnInit, Input, Output, EventEmitter, ViewEncapsulation, SimpleChanges, Inject } from '@angular/core';
import { Media } from './media';
import { MediaService } from '@geonature_common/service/media.service'
import { MatDialog } from "@angular/material";
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
  @Input() diaporama: boolean = false;

  public bInitialized = false;

  constructor(
    public ms: MediaService,
    public dialog: MatDialog,
  ) { }

  ngOnInit() {
    this.initMedias();
    this.ms.getNomenclatures().subscribe(() => { this.bInitialized = true; });
  }

  initMedias() {
    for (const index in this.medias) {
      if (!(this.medias[index] instanceof Media)) {
        this.medias[index] = new Media(this.medias[index]);
      }
    }
  }

  openDialog() {
    const dialogRef = this.dialog.open(MediaDialog, {
      width: '800px',
      data: { medias: this.medias, index: this.index },
    });
  }

  ngOnChanges(changes: SimpleChanges) {
    for (const propName in changes) {

      if (propName === 'medias') {
        this.initMedias();
      }
    }
  }
}
