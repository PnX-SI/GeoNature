import { Component } from "@angular/core";
import { MapListService } from "@geonature_common/map-list/map-list.service";
import { ValidationDataService } from "../../services/data.service";

import { ToastrService } from "ngx-toastr";
import { ModuleConfig } from "../../module.config";

@Component({
  selector: "pnx-validation-definitions",
  templateUrl: "validation-definitions.component.html",
  styleUrls: ["./validation-definitions.component.scss"],
  providers: []
})
export class ValidationDefinitionsComponent implements OnInit {
  public definitions;
  private showDefinitions: Boolean = false;
  public VALIDATION_CONFIG = ModuleConfig;

  constructor(
    public searchService: ValidationDataService,
    private toastr: ToastrService
  ) {}

  ngOnInit() {}

  getDefinitions(param) {
    this.showDefinitions = !this.showDefinitions;
    this.searchService.getDefinitionData().subscribe(
      result => {
        this.definitions = result;
      },
      error => {
        if (err.statusText === "Unknown Error") {
          // show error message if no connexion
          this.toastr.error("ERROR: IMPOSSIBLE TO CONNECT TO SERVER");
        } else {
          // show error message if other server error
          this.toastr.error(err.error);
        }
      }
    );
  }
}
