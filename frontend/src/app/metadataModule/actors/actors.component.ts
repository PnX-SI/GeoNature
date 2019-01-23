import { Component, OnInit, Input } from '@angular/core';
import { FormArray } from '@angular/forms';
import { DataFormService } from '@geonature_common/form/data-form.service';

@Component({
  selector: 'pnx-metadata-actor',
  templateUrl: 'actors.component.html'
})

export class ActorComponent implements OnInit {
  @Input() parentFormArray: FormArray;
  public organisms: Array<any>;
  public roles: Array<any>;
  constructor(private _dfs: DataFormService) { }

  ngOnInit() {
    this._dfs.getOrganisms().subscribe(data => {
      this.organisms = data;
    });
    this._dfs.getRoles({'group': false}).subscribe(data => {
      this.roles = data;
    });
  }
  deleteFormArray(i) {
    this.parentFormArray.removeAt(i);
  }


}
