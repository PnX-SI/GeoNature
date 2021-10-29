import { Injectable } from '@angular/core';
import { FormArray } from "@angular/forms";

import {DataFormService} from "@geonature_common/form/data-form.service"
import { NgbDateParserFormatter } from "@ng-bootstrap/ng-bootstrap";
import { OcctaxFormService } from "../occtax-form.service";
import {OcctaxFormOccurrenceService} from "./occurrence.service";

@Injectable()
export class OccurrenceSingletonService {
    public profilErrors: Array<any>;
    constructor(
        private _dataS: DataFormService,
        private dateParser: NgbDateParserFormatter,
        private occtaxFormService: OcctaxFormService,
        private occFormService: OcctaxFormOccurrenceService
    ) {
        this.profilErrors = [];
     }
    profilControl(cdRef:number) {    
        if(!cdRef) {
          return;
        }
    
        const releve = this.occtaxFormService.occtaxData.getValue().releve;
        const dateMin = this.dateParser.format(releve.properties.date_min);
        const dateMax = this.dateParser.format(releve.properties.date_min);
        // find all distinct id_nomenclature_life_stage if countings
        let idNomenclaturesLifeStage = new Set();
        (this.occFormService.form.get("cor_counting_occtax") as FormArray).controls.forEach(
          counting => {
            const control = counting.get("id_nomenclature_life_stage");
            if(control) {
              idNomenclaturesLifeStage.add(control.value)
            }
          });
        const postData = {
          cd_ref: cdRef,
          date_min: dateMin,
          date_max: dateMax,
          altitude_min: releve.properties.altitude_min,
          altitude_max: releve.properties.altitude_max,
          geom: releve.geometry,
          life_stages: Array.from(idNomenclaturesLifeStage)
        };
        this._dataS.controlProfile(postData).subscribe(
          data => {        
            this.profilErrors = data["errors"];
          },
          errors => {        
            this.profilErrors = [];
            
          }
          );
      }
}