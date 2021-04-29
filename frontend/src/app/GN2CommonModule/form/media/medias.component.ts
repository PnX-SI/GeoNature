import {
  Component,
  OnInit,
  Input,
  Output,
  EventEmitter,
  ViewEncapsulation,
  SimpleChanges
} from '@angular/core';
import { ConfigService } from '@geonature/utils/configModule/core';
import { FormControl } from '@angular/forms';
import { Media } from './media';
import { MediaService } from '@geonature_common/service/media.service';

@Component({
  selector: 'pnx-medias',
  templateUrl: './medias.component.html',
  styleUrls: ['./media.css']
})
export class MediasComponent implements OnInit {
  //  @Input() medias: Array<Media> = []; /** list of medias */
  //  @Output() mediasChange = new EventEmitter<Array<Media>>();

  @Input() schemaDotTable: string;
  @Input() sizeMax: number;

  @Input() default: Object = {};

  @Input() parentFormControl: FormControl;
  @Input() details = [];

  @Input() disabled = false;
  @Input() disabledTxt: string;

  /* fix #1083 Cacher les champs présents dans details */
  @Input() hideDetailsFields : boolean = false;

  public bInitialized: boolean;

  constructor(public ms: MediaService, private _configService: ConfigService) {}

  ngOnInit() {
    this.ms.getNomenclatures().subscribe(() => {
      this.bInitialized = true;
      this.initMedias();
    });
  }

  initMedias() {
    if (!this.bInitialized) {
      return;
    }
    console.log('init media')
    for (const index in this.parentFormControl.value) {
      if (!(this.parentFormControl.value[index] instanceof Media)) {
        this.parentFormControl.value[index] = new Media(this.parentFormControl.value[index]);
      }
    }
  }

  validOrLoadingMedias() {
    return this.ms.validOrLoadingMedias(this.parentFormControl.value);
  }

  onMediaChange() {
    console.log('mediachange', this.parentFormControl.value)
    this.parentFormControl.patchValue(this.parentFormControl.value);
  }

  addMedia() {
    if (!this.parentFormControl.value) {
      this.parentFormControl.patchValue([]);
    }
    this.parentFormControl.value.push(new Media(null));
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
      this.ms.deleteMedia(media.id_media).subscribe(() => {
        console.log(`delete media ${media.id_media}`);
      });
    }
    this.parentFormControl.patchValue(this.parentFormControl.value);
  }


  voidcheckNoChanges() {

  }

  ngOnChanges(changes: SimpleChanges) {
    for (const propName of Object.keys(changes)) {
      if (propName === 'parentFormControl') {
        this.initMedias();
      }
    }
  }
}
