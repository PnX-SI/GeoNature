import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';
import { AppConfig } from '../../../conf/app.config';
import {
  HttpClient, HttpParams
} from '@angular/common/http';

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
    private _route: ActivatedRoute,
    private _dateParser: NgbDateParserFormatter,
    private _http: HttpClient
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

  getDatasets(id_af: number) {
    var params: { [key: string]: any; } = {};
    params["id_acquisition_frameworks"] = [id_af];
    this._dfs.getDatasets(params, false).subscribe(results => {
      //console.log(results["data"]);
      this.datasets = results["data"];
    });
  }

  getAf(id_af: number) {
    this._dfs.getAcquisitionFrameworkDetails(id_af).subscribe(data => {
      this.af = data;
      data.acquisition_framework_start_date = this._dateParser.parse(
        data.acquisition_framework_start_date
      );
      data.acquisition_framework_end_date = this._dateParser.parse(
        data.acquisition_framework_end_date
      );
    });
  }


  formatDate(date_in_json) {
    var date_json = JSON.parse(date_in_json);
    var date_converted = date_json.day + "/" + date_json.month + "/" + date_json.year;
    return date_converted;
  }

  displayJSON() {
    var x;
    for (x in this.af.acquisition_framework_start_date) {
      console.log(x);
      console.log(this.af.acquisition_framework_start_date[x]);
    }
  }

}
