import { Component, OnInit, Output, Input, EventEmitter } from '@angular/core';
/** Ce composant permet d'afficher un input de type "text" de saisi libre d'une observateur */
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
