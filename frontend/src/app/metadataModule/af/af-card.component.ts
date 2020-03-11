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
        this.formalizeAf();
      }
    });
    // this._dfs.getAcquisitionFrameworks({ is_parent: 'true' }).subscribe(data => {
    //   this.acquisitionFrameworks = data;
    // });

    // console.log(this.acquisitionFrameworks);
  }

  getDatasets(id_af: number) {
    var params: {[key: string]: any;} = {};
    params["id_acquisition_frameworks"] = [id_af];
    this._dfs.getDatasets(params, false).subscribe(results => {
      console.log(results["data"]);
      this.datasets = results["data"];
    });

    
  }

  getAf(id_af: number) {
    this._dfs.getAcquisitionFramework(id_af).subscribe(data => {
      this.af = data;
      console.log(data);
      data.acquisition_framework_start_date = this._dateParser.parse(
        data.acquisition_framework_start_date
      );
      data.acquisition_framework_end_date = this._dateParser.parse(
        data.acquisition_framework_end_date
      );
    });
  }

  formalizeAf() {
    let params: HttpParams = new HttpParams();
    params = params.append('id_type', this.af['id_nomenclature_territorial_level']);
    this.af['nomenclature_territorial_level'] = this._http.get<any>(`${AppConfig.API_ENDPOINT}/nomenclatures/nomenclatures`, {
      params:params
    });

    // methode de collecte
    // origine
    // type de donnees
    // objectif
    // type de ressource
    // source status ?

  }

}
