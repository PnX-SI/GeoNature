import { Component, OnInit, Input, OnChanges } from '@angular/core';
import {NgbModal, ModalDismissReasons} from '@ng-bootstrap/ng-bootstrap';
import { DataFormService } from '../../../../core/GN2Common/form/data-form.service';
@Component({
  selector: 'pnx-areas-intersected-modal',
  templateUrl: 'areas-intersected-modal.component.html'
})

export class AreasIntersectedComponent implements OnInit, OnChanges {
  @Input() geojson: Array<any>;
  public areasIntersected = new Array();
  constructor( private _modalService: NgbModal, private _dfs: DataFormService) { }

  ngOnInit() {

   }

   openIntesectionModal(content) {
    this._modalService.open(content);
  }

  ngOnChanges(changes) {
    if (changes.geojson) {
      if (changes.geojson.currentValue !== undefined) {
        console.log(changes);
        this._dfs.getFormatedGeoIntersection(changes.geojson.currentValue)
        .subscribe(res => {
          this.areasIntersected = res;
        });
      }

    }
  }
}
