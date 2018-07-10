import { Component, OnInit } from '@angular/core';
import { DatatableComponent } from "@swimlane/ngx-datatable";
import { DataFormService } from '@geonature_common/form/data-form.service';
import { Router } from "@angular/router";



@Component({
  selector: 'pnx-dataset-list',
  templateUrl: './dataset-list.component.html'
})

export class DatasetListComponent implements OnInit {
  public datasets: Array<any>;
  public columns = [
    { prop: "id_dataset", name: "ID" },
    { prop: "dataset_name", name: "Nom" },
    { prop: "dataset_desc", name: "Description" },
  ]
  constructor(private _dfs: DataFormService, private _router: Router) { }

  ngOnInit() {
    this._dfs.getDatasets().subscribe(data => {
      this.datasets = data;
    });
  }

  datasetEdit(id_dataset) {
    this._router.navigate(['admin/dataset', id_dataset]);
  }
}
