import { Component, OnInit } from "@angular/core";
import { OcchabFormService } from "../services/form-service";

@Component({
  selector: "pnx-occhab-form",
  templateUrl: "occhab-form.component.html"
})
export class OccHabFormComponent implements OnInit {
  public height = "80vh";
  constructor(public occHabForm: OcchabFormService) {}

  ngOnInit() {}

  formatter(item) {
    return item.lb_hab_fr_complet.replace(/<[^>]*>/g, "");
  }

  test() {
    this.height = "50vh";
  }
}
