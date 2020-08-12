import { Observable, Subscription } from 'rxjs';
import { Component, OnInit, Input, Output, EventEmitter, ViewEncapsulation, SimpleChanges } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { Media } from './media'
import { mediaFormDefinitionsDict } from './media-form-definition';
import { FormBuilder } from '@angular/forms';
import { MediaService } from '@geonature_common/service/media-service'
import { HttpEventType, HttpResponse } from '@angular/common/http';
import value from '*.json';

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

  @Input() schemaDotTable: string;

  @Input() media: Media;
  @Output() mediaChange = new EventEmitter<Media>();

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

    this.mediaFormDefinition = Object.keys(mediaFormDefinitionsDict)
    .map((key) => ({ ...mediaFormDefinitionsDict[key], attribut_name: key }))

    if (this.mediaFormChange) {
      this.mediaFormChange.unsubscribe()
    }

    if (!this.mediaForm) {
      this.mediaForm = this._formBuilder.group({});
    }

    if (this.media) {
      this.media.id_table_location = this.media.id_table_location || this.idTableLocation;
      this.mediaForm.patchValue(this.media);
    }

    this.mediaFormChange = this.mediaForm.valueChanges.subscribe((values) => {

      if (Object.keys(this.mediaFormDefinition).length == Object.keys(this.mediaForm.value).length && this.watchChangeForm) {

        if (this.mediaFormInitialized) {
          this.media.setValues(values);
          if (values.file && (values.media_path || values.media_url)) {
            this.mediaForm.patchValue({
              media_path: null,
              media_url: null,
            });
            this.media.setValues({
              media_path: null,
              media_url: null,
            })
          }

          // Patch pourris pour les cas ou url est renseigné quadn le media existe
          if( this.media.id_media && this.media.url && this.media.bFile === 'Uploader un fichier') {
            this.mediaForm.patchValue({bFile: 'Renseigner une url'})
          }

          this.mediaChange.emit(this.media);
        } else {
          this.watchChangeForm = false;
          this.mediaForm.patchValue(this.media);
          this.watchChangeForm = true;
          this.mediaFormInitialized = true;
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
            this.mediaChange.emit(this.media);
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

      if (['media'].includes(propName)) {
        this.initForm();
      }

      if (propName === 'schemaDotTable') {
        this.initIdTableLocation(this.schemaDotTable);
      }

    }
  }

}
