import { Component, OnInit, Input } from "@angular/core";
import { FormControl, FormGroup } from "@angular/forms";
import { OcctaxFormService } from "../occtax-form.service";
import { ModuleConfig } from "../../module.config";
import { OcctaxFormCountingService } from "./counting.service";

@Component({
  selector: "pnx-occtax-form-counting",
  templateUrl: "./counting.component.html",
  styleUrls: ["./counting.component.scss"],
  provider: [OcctaxFormCountingService]
})
export class OcctaxFormCountingComponent implements OnInit {
  
  public occtaxConfig = ModuleConfig;
  @Input('form') countingForm: FormGroup;

  constructor(
    public fs: OcctaxFormService,
    private occtaxFormCountingService: OcctaxFormCountingService
  ) {}

  ngOnInit() {
    //this.occurrenceForm = this.occtaxFormOccurrenceService.form;
  } 
}
