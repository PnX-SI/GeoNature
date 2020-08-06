import { Observable, Subscription } from 'rxjs';
import { Component, OnInit, Input, Output, EventEmitter, ViewEncapsulation, SimpleChanges } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { Media } from './media'
import { mediaFormDefinitionsDict } from './media-form-definition';
import { FormBuilder } from '@angular/forms';
import { MediaService } from '@geonature_common/service/media-service'
import { HttpEventType, HttpResponse } from '@angular/common/http';

@Component({
  selector: 'pnx-media',
  templateUrl: './media.component.html',
  styleUrls: ['./media.scss'],
})
export class MediaComponent implements OnInit {

  public mediaFormDefinition = [];
  public mediaForm: FormGroup;

  public mediaFormChange: Subscription = null;

  public mediaSave: Media;

  // manage form loading TODO in dynamic from
  public mediaFormInitialized;
  public watchChangeForm: boolean = true;

  public uploadPercentDone: number;

  public idTableLocation: number;

  @Input() schemaDotTable: string;
  @Input() uuidAttachedRow: string;

  // manageState
  @Input() bEditable: boolean; //
  @Output() bEditableChange = new EventEmitter<boolean>();

  @Input() bEdit: boolean;
  @Output() bEditChange = new EventEmitter<boolean>();

  @Input() bFreeze: boolean;
  @Output() bFreezeChange = new EventEmitter<boolean>();

  @Input() bLoading: boolean;
  @Output() bLoadingChange = new EventEmitter<boolean>();


  @Input() media: Media;
  @Output() MediaChange = new EventEmitter<boolean>();

  @Output() validMediaChange = new EventEmitter<boolean>();

  @Output() actionProcessed = new EventEmitter<boolean>();

  constructor(
    private _formBuilder: FormBuilder,
    private _mediaService: MediaService
  ) { }

  ngOnInit() {
    this.initIdTableLocation(this.schemaDotTable)
    this.initForm();
  };

  initIdTableLocation(schemaDotTable) {
    if (!this.schemaDotTable) return;
    this._mediaService
      .getIdTableLocation(schemaDotTable)
      .subscribe((idTableLocation) => {
        this.idTableLocation = idTableLocation;
      });
    this.initForm();

  }

  emitChanges() {
    console.log('emit changes', this.mediaForm.valid)
    this.bFreezeChange.emit(this.bFreeze);
    this.bLoadingChange.emit(this.bLoading);
    this.bEditChange.emit(this.bEdit);
    this.validMediaChange.emit(this.mediaForm.valid);
  }

  initForm() {
    this.mediaFormInitialized = false;

    if (this.mediaFormChange) {
      this.mediaFormChange.unsubscribe()
    }

    this.mediaFormDefinition = Object.keys(mediaFormDefinitionsDict).map((key) => ({ ...mediaFormDefinitionsDict[key], attribut_name: key }))
    this.mediaForm = this._formBuilder.group({});

    if (this.media) {
      this.media.id_table_location = this.media.id_table_location || this.idTableLocation;
      this.media.uuid_attached_row = this.media.uuid_attached_row || this.uuidAttachedRow;
      this.mediaForm.patchValue(this.media);
    }

    this.mediaFormChange = this.mediaForm.valueChanges.subscribe((values) => {
      if (Object.keys(this.mediaFormDefinition).length == Object.keys(this.mediaForm.value).length && this.watchChangeForm) {

        if (this.mediaFormInitialized) {
          this.media.setValues(values);
          this.emitChanges();
        } else {
          this.watchChangeForm = false;
          this.mediaForm.patchValue(this.media);
          this.watchChangeForm = true;
          this.mediaFormInitialized = true;
        }
      }
    })
  }

  editMedia() {
    this.mediaSave = new Media(this.media)
    this.bEdit = true;
    this.bFreeze = true;
    this.emitAction('edit');
  }

  deleteMedia() {
    this.bEdit = false;
    this.bFreeze = false;
    this.emitAction('delete')
  }

  validMedia() {
    this.bEdit = false;
    this.bFreeze = false;
    this.bLoading = true;
    this._mediaService
      .postMedia(this.mediaForm.value.file, this.media)
      .subscribe(
        (event) => {
          if (event.type == HttpEventType.UploadProgress) {
            this.uploadPercentDone = Math.round(100 * event.loaded / event.total);
          } else if (event instanceof HttpResponse) {
            console.log('file downloaded')
            console.log(event)
            this.media.setValues(event.body);
            this.bLoading = false;
            this.mediaForm.patchValue({file: null});
            this.emitAction('valid');
          }
        },
        (err) => { console.log('Error on upload', err) });
  }

  cancelMedia() {
    this.media.setValues(this.mediaSave)
    this.mediaForm.patchValue(this.media);
    this.bFreeze = false;
    this.bEdit = false;
    this.emitAction('cancel')
  }

  emitAction(actionType) {
    this.emitChanges()
    this.actionProcessed.emit(actionType);
  }

  ngOnChanges(changes: SimpleChanges) {
    for (let propName in changes) {
      let chng = changes[propName];
      let cur = JSON.stringify(chng.currentValue);
      let prev = JSON.stringify(chng.previousValue);

      if (['media', 'bEdit', 'idTableLocation', 'uuidAttachedRow'].includes(propName)) {
        this.initForm();
      }

      if(['schemaDotTable']) {
        this.initIdTableLocation(this.schemaDotTable);
      }

    }
  }

}
