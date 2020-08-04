import { Component, OnInit, Input, Output, EventEmitter, ViewEncapsulation, SimpleChanges } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { Media } from './media'
import { mediaFormDefinitionsDict } from './media-form-definition';
import { FormBuilder } from '@angular/forms';


@Component({
  selector: 'pnx-media',
  templateUrl: './media.component.html',
  styleUrls: ['./media.scss'],
})
export class MediaComponent implements OnInit {

  public mediaFormDefinition = []
  public mediaForm: FormGroup;
  public mediaFormChange = null;
  public mediaFormInitialized;
  public watchChangeForm: boolean = true;

  @Input() media: Media;
  @Input() bEdit: boolean = false;

  @Output() onValidMediaChange = new EventEmitter();

  constructor(
    private _formBuilder: FormBuilder
  ) { }

  ngOnInit() {
    this.initForm();
  };

  initForm() {
    this.mediaFormInitialized = false;

    if (this.mediaFormChange) {
      this.mediaFormChange.unsuscribe
    }

    this.mediaFormDefinition = Object.keys(mediaFormDefinitionsDict).map((key) => ({ ...mediaFormDefinitionsDict[key], attribut_name: key }))
    this.mediaForm = this._formBuilder.group({});

    if (this.media) {
      this.mediaForm.patchValue(this.media);
    }

    this.mediaFormChange = this.mediaForm.valueChanges.subscribe((values) => {
      if (Object.keys(this.mediaFormDefinition).length == Object.keys(this.mediaForm.value).length && this.watchChangeForm) {

        if (this.mediaFormInitialized) {
          this.media.setValues(values);
          this.onValidMediaChange.emit(this.mediaForm.valid);

        } else {
          this.watchChangeForm = false;
          this.mediaForm.patchValue(this.media);
          this.watchChangeForm = true;
          this.mediaFormInitialized = true;
        }
      }
    })

  }

  ngOnChanges(changes: SimpleChanges) {
    for (let propName in changes) {
      let chng = changes[propName];
      let cur = JSON.stringify(chng.currentValue);
      let prev = JSON.stringify(chng.previousValue);

      if (propName === 'media') {
        this.initForm();
      }

      if (propName === 'edit') {
        this.initForm();
      }
    }
  }

}
