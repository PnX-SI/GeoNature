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
  public savedValues: Array<any>;
  constructor(private _dfs: DataFormService) {
    super();
  }

  ngOnInit() {
    this._dfs.getAcquisitionFrameworks().subscribe(data => {
      this.values = data;
      this.savedValues = data;
    });
  }

  filterItems(event) {
    this.values = super.filterItems(event, this.savedValues, 'acquisition_framework_name');
  }
}
