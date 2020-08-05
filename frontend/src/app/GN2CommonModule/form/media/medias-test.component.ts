import { Component, OnInit, Input, Output, EventEmitter, ViewEncapsulation } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { Media } from './media';
import { Router, ActivatedRoute, ParamMap } from '@angular/router';

@Component({
  selector: 'pnx-medias-test',
  templateUrl: './medias-test.component.html',
  styleUrls: ['./media.scss'],
  // encapsulation: ViewEncapsulation.None
})
export class MediasTestComponent implements OnInit {

  medias: Array<Media> = [];
  bValidForms: boolean = true;
  idTableLocation:number = 6;
  uuidAttachedRow: string;

  constructor(private _route: ActivatedRoute,) {}

  ngOnInit() {
  }

  onValidFormsChange(event) {
    this.bValidForms = event;
  }

}
