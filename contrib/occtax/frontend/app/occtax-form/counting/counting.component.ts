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

}
