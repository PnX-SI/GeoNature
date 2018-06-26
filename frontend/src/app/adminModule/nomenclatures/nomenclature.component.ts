import { Component, OnInit } from '@angular/core';
import { AppConfig } from '@geonature_config/app.config';
import { DomSanitizer } from '@angular/platform-browser';

@Component({
  selector: 'pnx-nomenclature-component',
  templateUrl: 'nomenclature.component.html',
  styleUrls: ['./nomenclature.component.scss']
})
export class NomenclatureComponent implements OnInit {
  public nomenclatureURL = AppConfig.API_ENDPOINT + '/nomenclatures/admin/bibnomenclaturestypes/';
  constructor(public sanitizer: DomSanitizer) {}

  ngOnInit() {}
}
