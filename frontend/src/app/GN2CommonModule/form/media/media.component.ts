import { Component, OnInit, Input, Output, EventEmitter, SimpleChanges } from '@angular/core';
import { UntypedFormGroup } from '@angular/forms';
import { Media } from './media';
import { mediaFormDefinitionsDict } from './media-form-definition';
import { UntypedFormBuilder } from '@angular/forms';
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
  public mediaForm: UntypedFormGroup;

  public mediaFormDefinition = null;

  public mediaFormInitialized = false;

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

  /* fix #1083 Cacher les champs présents dans details */
  @Input() hideDetailsFields: boolean = false;

  constructor(
    private _formBuilder: UntypedFormBuilder,
    public ms: MediaService,
    private _commonService: CommonService,
    private _dynformService: DynamicFormService
  ) {}

  ngOnInit() {
    this.mediaFormDefinition = this._dynformService.formDefinitionsdictToArray(
      mediaFormDefinitionsDict,
      {
        nomenclatures: this.ms.metaNomenclatures(),
        details: this.details,
        hideDetailsFields: this.hideDetailsFields,
      }
    );

    //if field not hidden => put it before advance setting
    let afterDisplay = false;
    let mediaDetailsFields = this.mediaFormDefinition.filter((field) => {
      if (afterDisplay && field.hidden !== true) {
        return true;
      }
      if (field.attribut_name == 'displayDetails') {
        afterDisplay = true;
      }
      return false;
    });

    //Si la liste de champs à afficher dans detail est différente de la liste des champs details
    if (mediaDetailsFields.length > 0 && (this.details || []).length != mediaDetailsFields.length) {
      let outDetailsFields = this.mediaFormDefinition.filter(
        (field) =>
          !(this.details || []).includes(field.attribut_name) && mediaDetailsFields.includes(field)
      );
      const cMediaFormDefinition = this.mediaFormDefinition;
      const newMediaFormDefinition = [];
      const formDefinitionDone = [];
      for (var i = 0; i < cMediaFormDefinition.length; i++) {
        //on met avant la checkbox les champs à montrer
        if (cMediaFormDefinition[i].attribut_name == 'displayDetails') {
          for (var j = 0; j < outDetailsFields.length; j++) {
            newMediaFormDefinition.push(outDetailsFields[j]);
            formDefinitionDone.push(outDetailsFields[j]);
          }
        }

        if (!formDefinitionDone.includes(cMediaFormDefinition[i])) {
          newMediaFormDefinition.push(cMediaFormDefinition[i]);
        }
      }
      //La liste des champs est réorganisée pour bien les afficher
      this.mediaFormDefinition = newMediaFormDefinition;
    }

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
    return this.media.sent
      ? ''
      : this.mediaFormReadyToSend()
      ? 'Veuillez valider le média en appuyant sur le bouton de validation'
      : this.media.bFile
      ? 'Veuillez compléter le formulaire et renseigner un fichier'
      : 'Veuillez compléter le formulaire et Renseigner une URL valide';
  }

  /**
   * le boutton est accessible si le formulaire est valide
   * et si media.sent est à false (il y a eu une modification depuis la dernière requête ou il n'y a pas eu de requete)
   */
  mediaFormReadyToSend() {
    if (!this.mediaForm) {
      return;
    }
    return this.mediaForm.valid && !this.media.sent;
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

    /* MET Ajout d'un filtre par code nomenclature */
    if (this.default['mnemonique_nomenclature_media_type']) {
      let nomenclatureMediaType = this.ms.getNomenclature(
        this.default['mnemonique_nomenclature_media_type'],
        'mnemonique',
        'TYPE_MEDIA'
      );
      if (nomenclatureMediaType) {
        this.media.id_nomenclature_media_type = nomenclatureMediaType.id_nomenclature;
      }
    }

    /* Fix #1078 Ajout d'un filtre par code nomenclature */
    if (this.default['mnemonique_nomenclature_media_type']) {
      let nomenclatureMediaType = this.ms.getNomenclature(
        this.default['mnemonique_nomenclature_media_type'],
        'mnemonique',
        'TYPE_MEDIA'
      );
      if (nomenclatureMediaType) {
        this.media.id_nomenclature_media_type = nomenclatureMediaType.id_nomenclature;
      }
    }

    this.mediaForm.patchValue(this.media);

    // Patch pourri pour être sûr d'avoir le bon media.sent
    setTimeout(() => {
      this.mediaFormInitialized = true;
    }, 500);
  }

  setValue(value) {
    this.media.setValues(value);
    this.mediaForm.patchValue(value);
  }

  onFormChange(value) {
    if (this.mediaFormInitialized) {
      this.media.sent = false;
    }

    this.bValidSizeMax = !(value.file && this.sizeMax) || value.file.size / 1000 < this.sizeMax;

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
      this.mediaForm.patchValue({
        media_path: null,
      });
    }

    this.mediaChange.emit(this.media);
  }

  onMediaFormInit(mediaForm) {
    this.mediaForm = mediaForm;
    this.initForm();
  }

  /** déclenché quand le formulaire est initialisé */
  initForm() {
    if (!(this.ms.bInitialized && this.mediaForm)) {
      return;
    }

    if (this.sizeMax) {
      mediaFormDefinitionsDict.file.sizeMax = this.sizeMax;
    }

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
