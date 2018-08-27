import { Component, OnInit, Input } from '@angular/core';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';

@Component({
  selector: 'pnx-acquisition-frameworks',
  templateUrl: './acquisition-frameworks.component.html'
})
export class AcquisitionFrameworksComponent extends GenericFormComponent implements OnInit {
  @Input() values: Array<any>;
  @Input() bindAllItem: false;
  constructor(private _dfs: DataFormService) {
    super();
  }

  ngOnInit() {
    this._dfs.getAcquisitionFrameworks().subscribe(data => {
      this.values = data;
    });
  }
}
