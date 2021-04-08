import { Component } from "@angular/core";
import { MapListService } from "@geonature_common/map-list/map-list.service";
import { ValidationDataService } from "../../services/data.service";
import { CommonService } from "@geonature_common/service/common.service";

@Component({
  selector: "pnx-validation-definitions",
  templateUrl: "validation-definitions.component.html",
  styleUrls: ["./validation-definitions.component.css"],
  providers: []
})
export class ValidationDefinitionsComponent {
  public definitions;
  private showDefinitions: Boolean = false;
  public moduleConfig: any;

  constructor(
    public searchService: ValidationDataService,
    private _commonService: CommonService,
  ) {}

  getDefinitions(param) {
    this.showDefinitions = !this.showDefinitions;
    this.searchService.getDefinitionData().subscribe(
      result => {
        this.definitions = result;
      },
      error => {
        if (error.statusText === "Unknown Error") {
          // show error message if no connexion
          this._commonService.translateToaster("error", "ERROR: IMPOSSIBLE TO CONNECT TO SERVER");
        } else {
          // show error message if other server error
          this._commonService.translateToaster("error", error.error);
        }
      }
    );
  }
}
