import { Component, OnInit, Input, Output, EventEmitter, ViewEncapsulation } from '@angular/core';
import { Media } from './media';
import { Router, ActivatedRoute, ParamMap } from '@angular/router';
import { AppConfig } from "@geonature_config/app.config";
import { FormGroup, FormBuilder, Validators } from "@angular/forms";


@Component({
  selector: 'pnx-medias-test',
  templateUrl: './medias-test.component.html',
  styleUrls: ['./media.scss'],
  // encapsulation: ViewEncapsulation.None
})
export class MediasTestComponent implements OnInit {

  public mediaForm: FormGroup;

  public appConfig = AppConfig;

  public formDefinitions = [
    {
      attribut_name: 'medias',
      attribut_label: "Médias",
      type_widget: 'medias',
      schema_dot_table: 'pr_occtax.t_occurrences_occtax',
      value: [

        {
          "bLoading": false,
          "uploadPercentDone": 100,
          "id_table_location": 5,
          "id_nomenclature_media_type": 468,
          "title_fr": "rty",
          "description_fr": "rty",
          "author": "rty",
          "bFile": "Renseigner une URL",
          "media_url": "https://www.lpo.fr/images/actualites/2019/appel_a_dons_hirondelles/image_actu.jpg",
          "file": null,
          "id_media": null,
          "uuid_attached_row": null,
          "media_path": null,
          "pendingRequest": null
        },
        {
          "bLoading": false,
          "uploadPercentDone": 0,
          "sent": false,
          "id_table_location": 5,
          "id_nomenclature_media_type": 471,
          "title_fr": "aze",
          "description_fr": "aze",
          "author": "aze",
          "bFile": "Renseigner une URL",
          "media_url": "http://www.web-ornitho.com/chants/accenteur.mouchet.wav",
          "file": null,
          "id_media": null,
          "uuid_attached_row": null,
          "media_path": null
        }
      ]
    }
  ];

  constructor(
    private _route: ActivatedRoute,
    private _formBuilder: FormBuilder,
      ) {}

  ngOnInit() {
    this.mediaForm = this._formBuilder.group({});
    // this.medias=[
    //   new Media({
    //     "bLoading": false,
    //     "uploadPercentDone": 0,
    //     "id_table_location": 5,
    //     "id_media": null,
    //     "title_fr": "zer",
    //     "description_fr": "zer",
    //     "uuid_attached_row": null,
    //     "media_path": null,
    //     "media_url":"https://www.monpetitcoinvert.com/blog/wp-content/uploads/2019/05/oiseau-mesange-bleue-730x420.jpg",
    //     "author": 'jacky jack'
    //   })
    // ]
  }
}
