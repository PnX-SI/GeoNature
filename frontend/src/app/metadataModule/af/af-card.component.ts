import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { DataFormService } from '@geonature_common/form/data-form.service';

@Component({
  selector: 'pnx-af-card',
  templateUrl: './af-card.component.html',
  styleUrls: ['./af-card.component.scss'],
})
export class AfCardComponent implements OnInit {
  public id_af: number;
  public af: any;
  public acquisitionFrameworks: any;
  public datasets: any;

  constructor(
    private _dfs: DataFormService,
    private _route: ActivatedRoute
  ) { }

  ngOnInit() {
    this._route.params.subscribe(params => {
      this.id_af = params['id'];
      if (this.id_af) {
        this.getAf(this.id_af);
        this.getDatasets(this.id_af);
      }
    });
    // this._dfs.getAcquisitionFrameworks({ is_parent: 'true' }).subscribe(data => {
    //   this.acquisitionFrameworks = data;
    // });

    // console.log(this.acquisitionFrameworks);
  }
  getAf(id_af: number) {
    this._dfs.getAcquisitionFrameworkDetails(id_af).subscribe(data => {
      this.af = data;
      if (this.af.acquisition_framework_start_date) {
        var start_date = new Date(this.af.acquisition_framework_start_date);
        this.af.acquisition_framework_start_date = start_date.toLocaleDateString();
      }
      if (this.af.acquisition_framework_end_date) {
        var end_date = new Date(this.af.acquisition_framework_end_date);
        this.af.acquisition_framework_end_date = end_date.toLocaleDateString();
      }
    });
  }

  getDatasets(id_af: number) {
    var params: { [key: string]: any; } = {};
    params["id_acquisition_frameworks"] = [id_af];
    this._dfs.getDatasets(params, false).subscribe(results => {
      this.datasets = results["data"];
      this.getImports();
    });
  }

  getImports() {
    for (let i = 0; i < this.datasets.length; i++) {
      this._dfs.getImports(this.datasets[i]["id_dataset"]).subscribe(data => {
        this.datasets[i]['imports'] = data;
      });
    }
  }
}
