import { Component, OnInit } from '@angular/core';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { HttpClient } from '@angular/common/http';
import { AppConfig } from '@geonature_config/app.config';
import { FormArray, FormGroup } from '@angular/forms';

@Component({
  selector: 'pnx-af-list',
  templateUrl: './af-list.component.html'
})
export class AfListComponent implements OnInit {
  public acquisitionFrameworks: any;
  constructor(private _dfs: DataFormService) {}

  ngOnInit() {
    this._dfs.getAcquisitionFrameworks().subscribe(data => {
      this.acquisitionFrameworks = data;
    });
  }
}
