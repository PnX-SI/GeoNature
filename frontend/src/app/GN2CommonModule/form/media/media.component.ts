import { Observable, Subscription } from 'rxjs';
import { Component, OnInit, Input, Output, EventEmitter, ViewEncapsulation, SimpleChanges } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { Media } from './media'
import { mediaFormDefinitionsDict } from './media-form-definition';
import { FormBuilder } from '@angular/forms';
import { MediaService } from '@geonature_common/service/media.service'
import { HttpEventType, HttpResponse } from '@angular/common/http';
import { CommonService } from "@geonature_common/service/common.service";


@Component({
  selector: 'pnx-media',
  templateUrl: './media.component.html',
  styleUrls: ['./media.scss'],
})
export class MediaComponent implements OnInit {

  public mediaSave: Media = new Media();

  public mediaForm: FormGroup;

  public mediaFormDefinition = [];

  public mediaFormChange: Subscription = null;

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
    public ms: MediaService,
    private _commonService: CommonService
  ) { }

  ngOnInit() {
    this.initIdTableLocation(this.schemaDotTable)
    this.initForm();
  };

  initIdTableLocation(schemaDotTable) {
    if (!this.schemaDotTable) { return };
    this.ms
      .getIdTableLocation(schemaDotTable)
      .subscribe((idTableLocation) => {
        this.idTableLocation = idTableLocation;
        this.initForm();
      });

  }

  message() {
    return this.mediaFormReadyToSent()
      ? 'Veuillez valider le média en appuyant sur le boutton de validation'
      : this.media.sent
      ? ''
      : this.media.bFile == 'Uploader un fichier'
      ? 'Veuillez compléter le fomrulaire et renseigner un fichier'
      : 'Veuillez compléter le formulaire et Renseigner une URL valide'

  }

  mediaFormReadyToSent() {

    return Object.keys(this.mediaForm.controls)
      .filter(key => key !== 'file')
      .every(key => this.mediaForm.controls[key].valid)
      && (
      (this.mediaForm.value.bFile === 'Uploader un fichier' &&
        (!!this.mediaForm.value.file || this.media.media_path))
      || this.mediaForm.value.bFile === 'Renseigner une URL'
      )
      && !this.media.sent;
  }

  initForm() {
    this.mediaFormInitialized = false;

    if (this.sizeMax) {
      mediaFormDefinitionsDict.file.sizeMax = this.sizeMax;
    }

    this.mediaFormDefinition = Object.keys(mediaFormDefinitionsDict)
      .map((key) => ({ ...mediaFormDefinitionsDict[key], attribut_name: key }))

    if (this.mediaFormChange) {
      this.mediaFormChange.unsubscribe();
    }

    if (!this.mediaForm) {
      this.mediaForm = this._formBuilder.group({});
    }

    if (this.media) {
      if (this.media.media_url) {
        this.media.bFile = 'Renseigner une URL';
      }
      this.media.id_table_location = this.media.id_table_location || this.idTableLocation;

      // PHOTO par defaut
      this.media.id_nomenclature_media_type = (
        this.media.id_nomenclature_media_type ||
        this.ms.getNomenclature('Photo', 'mnemonique', 'TYPE_MEDIA').id_nomenclature
      );

      this.mediaForm.patchValue(this.media);
    }

    this.mediaFormChange = this.mediaForm.valueChanges.subscribe((values) => {
      if (this.mediaSave.hasValue(values)) { return };
      console.log('change');
      console.log(this.mediaSave.hasValue(values), values, this.mediaSave);
      this.mediaSave.setValues(values);
      this.media.sent = false;
      if (Object.keys(this.mediaFormDefinition).length === Object.keys(this.mediaForm.value).length && this.watchChangeForm) {

        if (this.mediaFormInitialized) {
          this.watchChangeForm = false;

          this.bValidSizeMax = (!(values.file && this.sizeMax)) || ((values.file.size / 1000) < this.sizeMax)

          this.media.setValues(values);
          this.mediaSave.setValues(values);
          if (values.bFile == 'Renseigner une URL' && (values.media_path || values.file)) {
            this.mediaForm.patchValue({
              media_path: null,
              file: null,
            });
            this.media.setValues({
              media_path: null,
              file: null,
            });
          }

          if (values.bFile === 'Uploader un fichier' && (values.media_url)) {
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
          if (this.media.media_url) {
            this.media.bFile = 'Renseigner une URL';
          }
          this.watchChangeForm = false;
          this.mediaForm.patchValue(this.media);
          this.mediaFormInitialized = true;
          this.watchChangeForm = true;

        }
      }
    })
  }

  validMedia() {
    this.media.bLoading = true;
    this.media.pendingRequest = this.ms
      .postMedia(this.mediaForm.value.file, this.media)
      .subscribe(
        (event) => {
          if (event.type === HttpEventType.UploadProgress) {
            this.media.uploadPercentDone = Math.round(100 * event.loaded / event.total);
            // this.mediaChange.emit(this.media);
          } else if (event instanceof HttpResponse) {
            this.media.setValues(event.body);
            this.mediaForm.patchValue({ ...this.media, file: null });
            this.media.bLoading = false;
            this.mediaChange.emit(this.media);
            this.media.pendingRequest = null;
            this.media.sent = true;
          }
        },
        error => {
          this._commonService.regularToaster('error', `Erreur avec la requête : ${error && error.error}`);
          console.log(error.error);
          this.media.bLoading = false;
          this.media.pendingRequest = null;
        });
  }

  ngOnChanges(changes: SimpleChanges) {
    for (let propName in changes) {

      if (['media', 'sizeMax'].includes(propName)) {
        this.initForm();
      }

      if (propName === 'schemaDotTable') {
        this.initIdTableLocation(this.schemaDotTable);
      }

    }
  }

  round(val, dec) {
    const decPow = Math.pow(10, dec)
    return Math.round(val * decPow) / decPow;
  }

}
