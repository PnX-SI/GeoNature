import { Component, OnInit, Input, Output, EventEmitter, ViewEncapsulation, SimpleChanges } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { Media } from './media';
import { MediaService } from '@geonature_commons/services/media-service

@Component({
  selector: 'pnx-medias',
  templateUrl: './medias.component.html',
  styleUrls: ['./media.scss'],
})
export class MediasComponent implements OnInit {

  public freeze: boolean = false;
  public bEditMedias: Array<boolean> = [];
  public bValidMedias: Array<boolean> = [];
  public mediaSave: Media;
  public bLoading:boolean = false;

  @Input() medias: Array<Media> = []; /** list of medias */
  @Input() bEdit: boolean = false; /** component is editable */

  @Output() onValidFormsChange = new EventEmitter<boolean>();

  constructor(private _mediaService: MediaService) { }

  ngOnInit() {
    this.initMedias()
  };

  initMedias() {
    this.bEditMedias = this.medias.map(() => false);
    this.bValidMedias = this.medias.map(() => true);
  }

  onValidMediaChange(event, index) {
    this.bValidMedias[index] = event
    this.emitFormsChange();
  }

  emitFormsChange() {
    this.onValidFormsChange.emit(this.bValidMedias.every(v => v) && this.bEditMedias.every(v => !v))
  }

  addMedia() {
    this.mediaSave = null;
    this.medias.push(new Media());
    this.bEditMedias.push(true);
    this.bValidMedias.push(false);
    this.freeze = true;
    this.emitFormsChange()
  }

  validMedia(index) {
    this.bLoading = true;
    this.bEditMedias[index] = false;
    this.freeze = false;
    this.mediaService
    setTimeout(() => {
      this.emitFormsChange();
      this.bLoading = false;
    }, 1000);
  }

  deleteMedia(index) {
    this.medias.splice(index, 1);
    this.bEditMedias.splice(index, 1);
    this.bValidMedias.splice(index, 1);
    this.freeze = false;
    this.mediaSave = null;
    this.emitFormsChange()
  }

  cancelMedia(index) {
    if (!this.mediaSave) {
      return this.deleteMedia(index)
    }

    this.medias[index] = new Media(this.mediaSave)
    this.bEditMedias[index] = false;
    this.freeze = false;
    this.mediaSave = null;
    this.emitFormsChange()
  }

  editMedia(index) {
    this.mediaSave = new Media(this.medias[index])
    this.bEditMedias[index] = true;
    this.freeze = true;
    this.emitFormsChange()
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
