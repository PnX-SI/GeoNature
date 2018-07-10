import { Component, OnInit } from '@angular/core';
import { FormGroup, FormBuilder } from '@angular/forms';
import { DataFormService } from '@geonature_common/form/data-form.service';

@Component({
  selector: 'pnx-af-form',
  templateUrl: './af-form.component.html'
})
export class AfFormComponent implements OnInit {
  public afForm: FormGroup;
  public acquisitionFrameworks;

  constructor(private _fb: FormBuilder, private _dfs: DataFormService) {}

  ngOnInit() {
    this._dfs.getAcquisitionFrameworks().subscribe(data => {
      this.acquisitionFrameworks = data;
    });
    this.afForm = this._fb.group({
      acquisition_framework_name: null,
      acquisition_framework_desc: null,
      id_nomenclature_territorial_level: null,
      territory_desc: null,
      keywords: null,
      id_nomenclature_financing_type: true,
      target_description: false,
      ecologic_or_geologic_target: null,
      acquisition_framework_parent_id: null,
      is_parent: null,
      acquisition_framework_start_date: null,
      acquisition_framework_end_date: null
    });
  }
}
