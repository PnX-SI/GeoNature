import { Component, OnInit, Input, Output, EventEmitter, ViewEncapsulation, SimpleChanges } from '@angular/core';
import { Media } from './media';

@Component({
  selector: 'pnx-medias',
  templateUrl: './medias.component.html',
  styleUrls: ['./media.scss'],
})
export class MediasComponent implements OnInit {

  public bFreeze: boolean = false;
  public bEditMedias: Array<boolean> = [];
  public bValidMedias: Array<boolean> = [];
  public mediaSave: Media;
  public bLoading:boolean = false;

  @Input() medias: Array<Media> = []; /** list of medias */
  @Output() mediasChange = new EventEmitter<Array<Media>>();
  @Input() bEditable: boolean = false; /** component is editable */

  @Input() schemaDotTable: string;
  @Input() uuidAttachedRow: string;

  @Output() validFormsChange = new EventEmitter<boolean>();


  ngOnInit() {
    this.initMedias()
  };

  onActionProcessed(event, index) {
    switch (event) {
      case 'delete':
        this.deleteMedia(index);
        break;

      default:
        break;
    }
  }

  initMedias() {
    this.bEditMedias = this.medias.map(() => false);
    this.bValidMedias = this.medias.map(() => true);
  }

  onValidMediaChange(event, index) {
    this.bValidMedias[index] = event
    this.emitFormsChange();
  }

  emitFormsChange() {
    this.validFormsChange.emit(this.bValidMedias.every(v => v) && this.bEditMedias.every(v => !v))
  }

  addMedia() {
    this.medias.push(new Media());
    this.bEditMedias.push(true);
    this.bValidMedias.push(false);
    this.bFreeze = true;
    this.emitFormsChange()
  }

  deleteMedia(index) {
    this.medias.splice(index, 1);
    this.bEditMedias.splice(index, 1);
    this.bValidMedias.splice(index, 1);
    this.bFreeze = false;
    this.emitFormsChange()
  }

  cancelMedia(index) {
    this.emitFormsChange()
  }

  editMedia(index) {
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
