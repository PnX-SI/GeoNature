import { Component, Input } from "@angular/core";
import { FormControl, FormGroup } from "@angular/forms";
import { OcctaxFormService } from "../occtax-form.service";
import { ModuleConfig } from "../../module.config";
import { AppConfig } from "@geonature_config/app.config";
import { OcctaxFormOccurrenceService } from "../occurrence/occurrence.service";
import { OcctaxFormCountingService } from "./counting.service";

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
    public occtaxFormOccurrenceService: OcctaxFormOccurrenceService
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

}
