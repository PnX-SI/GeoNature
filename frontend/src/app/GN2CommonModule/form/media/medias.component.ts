import { Component, OnInit, Input } from '@angular/core';
import { UntypedFormControl } from '@angular/forms';
import { Media } from './media';
import { MediaService } from '@geonature_common/service/media.service';
import { ConfigService } from '@geonature/services/config.service';
import { distinctUntilChanged } from '@librairies/rxjs/operators';

@Component({
  selector: 'pnx-medias',
  templateUrl: './medias.component.html',
  styleUrls: ['./media.scss'],
})
export class MediasComponent implements OnInit {
  @Input() schemaDotTable: string;
  @Input() sizeMax: number;

  @Input() default: Object = {};

  @Input() parentFormControl: UntypedFormControl;
  @Input() details = [];

  @Input() disabled = false;
  @Input() disabledTxt: string;
  /* fix #1083 Cacher les champs présents dans details */
  @Input() hideDetailsFields: boolean = false;

  public bInitialized: boolean;

  constructor(
    public ms: MediaService,
    public config: ConfigService
  ) {}

  ngOnInit() {
    this.ms.getNomenclatures().subscribe(() => {
      this.initMedias();
      // Subscribe sur la valeur du composant formulaire
      //  cas ou l'initialisation des valeurs du formulaire est asynchrone
      this.parentFormControl.valueChanges.pipe(
        distinctUntilChanged()
      ).subscribe(value => {
         this.initMedias();
      });
    });

  }

  initMedias() {
    // Initialisation des médias
    // Si le form control à bien une valeur (array vide)
    // Cast des objets en média
    // le composant est considéré comme initialisé (bInitialized = true)
    if (this.parentFormControl.value) {
      for (const index in this.parentFormControl.value) {
        if (!(this.parentFormControl.value[index] instanceof Media)) {
          this.parentFormControl.value[index] = new Media(this.parentFormControl.value[index]);
        }
      }
      this.bInitialized = true;
    }
  }

  validOrLoadingMedias() {
    return this.ms.validOrLoadingMedias(this.parentFormControl.value);
  }

  onMediaChange() {
    this.parentFormControl.patchValue(this.parentFormControl.value);
  }

  addMedia() {
    if (!this.parentFormControl.value) {
      this.parentFormControl.patchValue([]);
    }
    this.parentFormControl.value.push(new Media({}));
    this.parentFormControl.patchValue(this.parentFormControl.value);
  }

  deleteMedia(index) {
    const media = this.parentFormControl.value.splice(index, 1)[0];

    // si l upload est en cours
    if (media.pendingRequest) {
      media.pendingRequest.unsubscribe();
      media.pendingRequest = null;
    }

    // si le media existe déjà en base => route DELETE
    if (media.id_media) {
      this.ms.deleteMedia(media.id_media).subscribe();
    }
    this.parentFormControl.patchValue(this.parentFormControl.value);
  }
}
