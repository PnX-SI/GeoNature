import { divIcon } from "leaflet";

import { Component, OnInit, Input, Output, EventEmitter, ViewEncapsulation } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { Media } from './media';

@Component({
  selector: 'pnx-medias-test',
  templateUrl: './medias-test.component.html',
  styleUrls: ['./media.scss'],
  // encapsulation: ViewEncapsulation.None
})
export class MediasTestComponent implements OnInit {

  medias:Array<Media> = [];
  bValidForms:boolean = true;

  ngOnInit() {
    const media = new Media(  {
      "id_media": null,
      "id_table_location": null,
      "uuid_attached_row": null,
      "unique_id_media": null,
      "title_fr": "az",
      "description_fr": "az",
      "media_url": null,
      "media_path": null,
      "id_nomenclature_media_type": 471,
      "file": "C:\\fakepath\\qgis.desktop"
    })
    this.medias.push(media);

    this.

  }

  onValidFormsChange(event) {
    this.bValidForms=event;
  }

  validMedias() {
    console.log('valid média')

    // route + etc...
  }

}
