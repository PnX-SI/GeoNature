import { Observable, Subscription } from 'rxjs';
import { Component, OnInit, Input, Output, EventEmitter, ViewEncapsulation, SimpleChanges } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { Media } from './media'
import { mediaFormDefinitionsDict } from './media-form-definition';
import { FormBuilder } from '@angular/forms';
import { MediaService } from '@geonature_common/service/media.service'
import { HttpEventType, HttpResponse } from '@angular/common/http';

@Component({
  selector: 'pnx-media',
  templateUrl: './media.component.html',
  styleUrls: ['./media.scss'],
})
export class MediaComponent implements OnInit {

  public mediaForm: FormGroup;

  public mediaFormDefinition = [];

  public mediaFormChange: Subscription = null;

  public mediaSave: Media;

  // manage form loading TODO in dynamic from
  public mediaFormInitialized;
  public watchChangeForm: boolean = true;

  public idTableLocation: number;

  public bValidSizeMax: boolean = true;

  @Input() schemaDotTable: string;

  @Input() media: Media;
  @Output() mediaChange = new EventEmitter<Media>();

  @Input() sizeMax: number;

  @Output() validMediaChange = new EventEmitter<boolean>();

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
        this.initForm();
      });

  }

  initForm() {
    this.mediaFormInitialized = false;

    if(this.sizeMax) {
      mediaFormDefinitionsDict.file.sizeMax=this.sizeMax;
    }

    this.mediaFormDefinition = Object.keys(mediaFormDefinitionsDict)
    .map((key) => ({ ...mediaFormDefinitionsDict[key], attribut_name: key }))

    if (this.mediaFormChange) {
      this.mediaFormChange.unsubscribe()
    }

    if (!this.mediaForm) {
      this.mediaForm = this._formBuilder.group({});
    }

    if (this.media) {
      if( this.media.media_url) {
        this.media.bFile = 'Renseigner une url';
      }
      this.media.id_table_location = this.media.id_table_location || this.idTableLocation;

      this.mediaForm.patchValue(this.media);
    }

    this.mediaFormChange = this.mediaForm.valueChanges.subscribe((values) => {
      if (Object.keys(this.mediaFormDefinition).length == Object.keys(this.mediaForm.value).length && this.watchChangeForm) {

        if (this.mediaFormInitialized) {
          this.watchChangeForm = false;

          this.bValidSizeMax = (!(values.file && this.sizeMax)) || (values.file.size < this.sizeMax)

          this.media.setValues(values);
          if (values.bFile == 'Renseigner une url' && (values.media_path || values.file)) {
            this.mediaForm.patchValue({
              media_path: null,
              file: null,
            });
            this.media.setValues({
              media_path: null,
              file: null,
            });
          }

          if (values.bFile == 'Uploader un fichier' && (values.media_url)) {
            this.watchChangeForm = false;
            this.mediaForm.patchValue({
              media_url: null,
            });
            this.media.setValues({
              media_url: null,
            });
          }

          if (values.file && values.media_path) {
            this.mediaForm.patchValue({
              media_path: null,
            });
            this.media.setValues({
              media_path: null,
            });
          }

          this.mediaChange.emit(this.media);
          this.watchChangeForm = true;
        } else {
          // init forms
          if( this.media.media_url) {
            this.media.bFile = 'Renseigner une url';
          }
          this.watchChangeForm = false;
          this.mediaForm.patchValue(this.media);
          this.mediaFormInitialized = true;
          this.watchChangeForm = true;

        }
      }
    })
  }

  uploadMedia() {
    this.media.bLoading = true;
    this.media.pendingRequest = this._mediaService
      .postMedia(this.mediaForm.value.file, this.media)
      .subscribe(
        (event) => {
          if (event.type == HttpEventType.UploadProgress) {
            this.media.uploadPercentDone = Math.round(100 * event.loaded / event.total);
            // this.mediaChange.emit(this.media);
          } else if (event instanceof HttpResponse) {
            this.media.setValues(event.body);
            this.mediaForm.patchValue({ ...this.media, file: null });
            this.media.bLoading = false;
            this.mediaChange.emit(this.media);
            this.media.pendingRequest = null;
          }
        },
        (err) => { console.log('Error on upload', err) });
  }

  ngOnChanges(changes: SimpleChanges) {
    for (let propName in changes) {
      let chng = changes[propName];
      let cur = JSON.stringify(chng.currentValue);
      let prev = JSON.stringify(chng.previousValue);

      if (['media', 'sizeMax'].includes(propName)) {
        this.initForm();
      }

      if (propName === 'schemaDotTable') {
        this.initIdTableLocation(this.schemaDotTable);
      }

    }
  }

}
