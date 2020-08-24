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
export class OcctaxFormCountingComponent{
  
  public occtaxConfig = ModuleConfig;
  public appConfig = AppConfig;

  @Input('form') countingForm: FormGroup;

  constructor(
    public fs: OcctaxFormService,
    public occtaxFormOccurrenceService: OcctaxFormOccurrenceService
  ) {}

  defaultsMedia() {
    const occtaxData = this.fs.occtaxData.getValue();
    const observers = occtaxData.releve.properties.observers;
    const date_min = occtaxData.releve.properties.date_min;
    
    const occurrence = this.occtaxFormOccurrenceService.occurrence.getValue();
    const cd_nom = occurrence.cd_nom;
    return {
      details: false,
      author: observers.join(', '),
      title_fr: `${cd_nom} ${date_min}`
    }

  }

}
