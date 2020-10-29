import { Component, Input } from "@angular/core";
import { FormControl, FormGroup } from "@angular/forms";
import { OcctaxFormService } from "../occtax-form.service";
import { ModuleConfig } from "../../module.config";
import { AppConfig } from "@geonature_config/app.config";
import { OcctaxFormOccurrenceService } from "../occurrence/occurrence.service";
import { OcctaxFormCountingService } from "./counting.service";

import { OcctaxDataService } from "../../services/occtax-data.service";
import { CommonService } from '@geonature_common/service/common.service';

@Component({
  selector: "pnx-occtax-form-counting",
  templateUrl: "./counting.component.html",
  styleUrls: ["./counting.component.scss"]
})
export class OcctaxFormCountingComponent {

  public occtaxConfig = ModuleConfig;
  public appConfig = AppConfig;

  @Input('form') countingForm: FormGroup;

  constructor(
    public fs: OcctaxFormService,
    public occtaxFormOccurrenceService: OcctaxFormOccurrenceService,
    private occtaxDataService: OcctaxDataService,
    private _commonService: CommonService
  ) { }

  taxref() {
    const taxref = this.occtaxFormOccurrenceService.taxref.getValue();
    return taxref;
  }

  defaultsMedia() {
    const occtaxData = this.fs.occtaxData.getValue();
    const taxref = this.occtaxFormOccurrenceService.taxref.getValue();

    if (!(occtaxData && taxref)) {
      return {
        displayDetails: false,
      }
    }

    const observers = (occtaxData && occtaxData.releve.properties.observers) || [];
    const author = observers.map(o => o.nom_complet).join(', ');

    const date_min = (occtaxData && occtaxData.releve.properties.date_min) || null;


    const cd_nom = String(taxref && taxref.cd_nom) || '';
    const lb_nom = (taxref && `${taxref.lb_nom}`) || '';
    const date_txt = date_min ? `${date_min.year}_${date_min.month}_${date_min.day}` : ''
    const date_txt2 = date_min ? `${date_min.day}/${date_min.month}/${date_min.year}` : ''

    return {
      displayDetails: false,
      author: author,
      title_fr: `${date_txt}_${lb_nom.replace(' ', '_')}_${cd_nom}`,
      description_fr: `${lb_nom} observé le ${date_txt2}`,
    }
  }

  controlOccurenceEvent() {
    let inputData = {
      //cd_nom: this.occtaxFormOccurrenceService.form.get("cd_nom").value,
      cd_nom: 92,
      date_min: '2020-01-01',
      date_max: '2020-01-01',
      altitude_min: 500,
      altitude_max: 500,
      geom: '{"type":"Point","coordinates":[-0.1382130668760273,42.84541211851485]}'
    }
    //this.occtaxFormOccurrenceService.form.cor_counting_occtax.id_nomenclature_life_stage

    this.occtaxDataService.controlOccurence(inputData).subscribe(
      data => {
        //this._commonService.translateToaster('warning', JSON.stringify(data));
        this._commonService.translateToaster('warning', this.occtaxFormOccurrenceService.form.get("id_nomenclature_obs_technique").value);
      },
      err => {



        console.log(err);
        if (err.status === 404) {
          this._commonService.translateToaster('warning', 'Aucun profile');
        } else if (err.statusText === 'Unknown Error') {
          // show error message if no connexion
          this._commonService.translateToaster(
            'error',
            'ERROR: IMPOSSIBLE TO CONNECT TO SERVER (check your connection)'
          );
        } else {
          // show error message if other server error
          this._commonService.translateToaster('error', err.error);
        }
      },
      () => {
        //console.log(this.statusNames);
      }
    );
  }

}
