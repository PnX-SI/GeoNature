import { Observable, Subscription } from 'rxjs';
import {
  Component,
  OnInit,
  Input,
  Output,
  EventEmitter,
  ViewEncapsulation,
  SimpleChanges,
} from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { Media } from './media';
import { mediaFormDefinitionsDict } from './media-form-definition';
import { FormBuilder } from '@angular/forms';
import { MediaService } from '@geonature_common/service/media.service';
import { HttpEventType, HttpResponse } from '@angular/common/http';
import { CommonService } from '@geonature_common/service/common.service';
import { DynamicFormService } from '../dynamic-form-generator/dynamic-form.service';

@Component({
  selector: 'pnx-media',
  templateUrl: './media.component.html',
  styleUrls: ['./media.scss'],
})
export class MediaComponent implements OnInit {

  // public mediaSave: Media = new Media();

  public mediaForm: FormGroup;

  public mediaFormDefinition = [];

  // public mediaFormChange: Subscription = null;


  // manage form loading TODO in dynamic from
  public formInitialized;
  // public watchChangeForm = true;

  public idTableLocation: number;

  public bValidSizeMax = true;

  public errorMsg: string;

  @Input() schemaDotTable: string;

  @Input() media: Media;
  @Output() mediaChange = new EventEmitter<Media>();

  @Input() sizeMax: number;

  @Input() default: Object = {};

  @Output() validMediaChange = new EventEmitter<boolean>();

  @Input() details = [];

  constructor(
    private _formBuilder: FormBuilder,
    public ms: MediaService,
    private _commonService: CommonService,
    private _dynformService: DynamicFormService,
  ) { }

  ngOnInit() {
    this.initIdTableLocation(this.schemaDotTable);
    this.ms.getNomenclatures().subscribe(() => {
      this.initForm();
    });
  }

  initIdTableLocation(schemaDotTable) {
    if (!this.schemaDotTable) {
      return;
    }
    this.ms.getIdTableLocation(schemaDotTable).subscribe((idTableLocation) => {
      this.idTableLocation = idTableLocation;
      this.initForm();
    });
  }

  message() {
    return this.mediaFormReadyToSend()
      ? 'Veuillez valider le média en appuyant sur le bouton de validation'
      : this.media.sent
        ? ''
        : this.media.bFile
          ? 'Veuillez compléter le formulaire et renseigner un fichier'
          : 'Veuillez compléter le formulaire et Renseigner une URL valide';
  }

  /**
   * TODO simplifier
   */
  mediaFormReadyToSend() {
    if (!this.mediaForm) { return; }
    return (
      Object.keys(this.mediaForm.controls)
        .filter((key) => key !== 'file')
        .every((key) => this.mediaForm.controls[key].valid) &&
      ((this.mediaForm.value.bFile &&
        (!!this.mediaForm.value.file || this.media.media_path)) ||
        !this.mediaForm.value.bFile) &&
      !this.media.sent
    );
  }

  /**
   *
   */
  setFormInitValue() {
    if (!this.media) {
      return;
    }

    // si on a une url => bFile = false
    if (this.media.media_url) {
      this.media.bFile = false;
    }

    // id_table_location
    this.media.id_table_location = this.media.id_table_location || this.idTableLocation;

    // valeurs par défaut si null (depuis l'input default)
    for (const key of Object.keys(this.default)) {
      this.media[key] = this.media[key] || this.default[key];
    }

    // PHOTO par defaut TODO : comment le mettre dans default
    this.media.id_nomenclature_media_type =
      this.media.id_nomenclature_media_type ||
      this.ms.getNomenclature('Photo', 'mnemonique', 'TYPE_MEDIA').id_nomenclature;

    this.mediaForm.patchValue(this.media);
  }

  setValue(value) {
    this.media.setValues(value);
    this.mediaForm.patchValue(value);
  }

  onFormChange(value) {
    this.media.sent = false;

    this.bValidSizeMax =
      !(value.file && this.sizeMax) || value.file.size / 1000 < this.sizeMax;

    this.media.setValues(value);

    // si bFile = false
    // => media_path et file passent à null
    if (!value.bFile && (value.media_path || value.file)) {
      this.setValue({
        media_path: null,
        file: null,
      });
    }

    // si bFile = true
    // => media_url = null
    if (value.bFile && value.media_url) {
      this.mediaForm.setValue({
        media_url: null,
      });
    }

    // si le type de media implique une url
    // => media_path et file passent à null
    const label_fr = this.ms.getNomenclature(value.id_nomenclature_media_type).label_fr;
    if (
      ['Vidéo Dailymotion', 'Vidéo Youtube', 'Vidéo Vimeo', 'Page web'].includes(label_fr) &&
      value.bFile
    ) {
      this.setValue({
        bFile: false,
        media_path: null,
      });
    }

    // si type de media implique un fichier
    // => bFile = true et media_url = null
    if (['Vidéo (fichier)'].includes(label_fr) && !value.bFile) {
      this.mediaForm.setValue({
        bFile: true,
        media_url: null,
      });
    }

    // si un fichier est sélectionné
    // => media_path passe à null
    if (value.file && value.media_path) {
      this.mediaForm.setValue({
        media_path: null,
      });
    }

    this.mediaChange.emit(this.media);
  }

  /** déclenché quand le formulaire est initialisé */
  initForm() {
    if (!this.ms.bInitialized && this.formInitialized) { return; }

    if (this.sizeMax) {
      mediaFormDefinitionsDict.file.sizeMax = this.sizeMax;
    }

    this.mediaFormDefinition = this._dynformService
      .formDefinitionsdictToArray(
        mediaFormDefinitionsDict,
        {
          nomenclatures: this.ms.metaNomenclatures(),
          details: this.details
        }
      );

    this.setFormInitValue();

  }

  postMedia() {
    this.media.bLoading = true;
    this.media.pendingRequest = this.ms.postMedia(this.mediaForm.value.file, this.media).subscribe(
      (event) => {
        if (event.type === HttpEventType.UploadProgress) {
          this.media.uploadPercentDone = Math.round((100 * event.loaded) / event.total);
          // this.mediaChange.emit(this.media);
        } else if (event instanceof HttpResponse) {
          this.media.setValues(event.body);
          this.mediaForm.patchValue({ ...this.media, file: null });
          this.media.bLoading = false;
          this.media.sent = true;
          this.media.pendingRequest = null;
          this.errorMsg = '';
          this.mediaChange.emit(this.media);
        }
      },
      (error) => {
        this._commonService.regularToaster(
          'error',
          `Erreur avec la requête : ${error && error.error}`
        );
        this.errorMsg = error.error;
        this.media.bLoading = false;
        this.media.pendingRequest = null;
      }
    );
  }

  ngOnChanges(changes: SimpleChanges) {
    for (const propName of Object.keys(changes)) {
      if (['media', 'sizeMax'].includes(propName)) {
        this.initForm();
      }

      if (propName === 'schemaDotTable') {
        this.initIdTableLocation(this.schemaDotTable);
      }
    }
  }

  /**
   * Pour l'affichage des tailles
   */
  round(val, dec) {
    const decPow = Math.pow(10, dec);
    return Math.round(val * decPow) / decPow;
  }
}
