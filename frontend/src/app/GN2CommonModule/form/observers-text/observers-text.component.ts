import { Component, OnInit, Output, Input, EventEmitter } from '@angular/core';
import { FormControl } from '@angular/forms';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';

@Component({
  selector: 'pnx-observers-text',
  templateUrl: 'observers-text.component.html',
  styleUrls: ['./observers-text.component.scss']
})
export class ObserversTextComponent extends GenericFormComponent implements OnInit {
  constructor() {
    super();
  }

  ngOnInit() {}
}
