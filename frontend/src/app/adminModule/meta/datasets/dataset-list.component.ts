import { Component, OnInit, ViewChild } from '@angular/core';
import { DatatableComponent } from "@swimlane/ngx-datatable";
import { DataFormService } from '@geonature_common/form/data-form.service';
import { Router } from "@angular/router";
import { AdminStoreService } from '../../services/admin-store.service';




@Component({
  selector: 'pnx-dataset-list',
  templateUrl: './dataset-list.component.html',

})

export class DatasetListComponent implements OnInit {
  public datasets = [];
  public temp = [];
  public columns = [
    { prop: "id_dataset", name: "ID" },
    { prop: "dataset_name", name: "Nom" },
    { prop: "dataset_desc", name: "Description" },
  ]
  @ViewChild(DatatableComponent) table: DatatableComponent;

  constructor(private _dfs: DataFormService, private _router: Router, public adminStoreService: AdminStoreService) { }

  ngOnInit() {
    this._dfs.getDatasets().subscribe(results => {
      // cache our list
      this.temp = results['data'];
      this.datasets = results['data'];
    });
  }

  datasetEdit(id_dataset) {
    this._router.navigate(['admin/dataset', id_dataset]);
  }

  updateFilter(event) {
    const val = event.target.value.toLowerCase();

    // filter our data
    this.datasets = this.temp.filter(function(d) {
      return d.dataset_name.toLowerCase().indexOf(val) !== -1 || !val;
    });

    // Whenever the filter changes, always go back to the first page
    this.table.offset = 0;
  }
}


