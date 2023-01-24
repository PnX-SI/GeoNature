import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { FormGroup, FormBuilder} from '@angular/forms';
import { MediaService } from '@geonature_common/service/media.service';

@Component({
  selector: 'pnx-medias-test',
  templateUrl: './medias-test.component.html',
  styleUrls: ['./media.scss'],
  // encapsulation: ViewEncapsulation.None
})
export class MediasTestComponent implements OnInit {
  public mediaForm: FormGroup;

  bInitialized = false;

  public formDefinitions = [
    {
      attribut_name: 'medias',
      attribut_label: 'Médias',
      type_widget: 'medias',
      schema_dot_table: 'pr_occtax.t_occurrences_occtax',
      value: [],
      default: {
        uuid_attached_row: null,
        title_fr: 'Media test',
        author: 'media testeur',
        displayDetails: false,
      },
      details: ['title_fr', 'description_fr', 'id_nomenclature_media_type', 'author', 'bFile'],
      switch_details: true,
    },
  ];

  constructor(
    private _route: ActivatedRoute,
    public ms: MediaService,
    private _formBuilder: FormBuilder,
  ) {
  }

  ngOnInit() {
    // test TODO remove
    const a = {};
    const s = 'a["f"] = a => !!a';
    eval(s);
    console.log(a['f'](1));
    this.mediaForm = this._formBuilder.group({});
    this._route.params.subscribe((params) => {
      if (params['uuidAttachedRow']) {
        this.formDefinitions[0].default.uuid_attached_row = params['uuidAttachedRow'];
        this.ms.getMedias(params['uuidAttachedRow']).subscribe((medias) => {
          this.formDefinitions[0].value = medias;
          this.mediaForm.patchValue(medias || []);
          this.bInitialized = true;
        });
      }
    });
  }
}
