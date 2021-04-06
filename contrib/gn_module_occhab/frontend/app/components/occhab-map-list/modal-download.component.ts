import { Component, OnInit, Input } from "@angular/core";
import { NgbActiveModal } from "@ng-bootstrap/ng-bootstrap";
import { OccHabDataService } from "../../services/data.service";
import { OcchabStoreService } from "../../services/store.service";
import { ConfigService } from "@geonature/utils/configModule/core";
import { moduleCode } from "../../module.code.config";

@Component({
  selector: "pnx-occhab-map-list-download-modal",
  templateUrl: "modal-download.component.html"
})
export class OccHabModalDownloadComponent implements OnInit {
  public moduleConfig: any;
  @Input() tooManyObs = false;
  constructor(
    public activeModal: NgbActiveModal,
    private _occHabDataService: OccHabDataService,
    private _configService: ConfigService,
    public storeService: OcchabStoreService,
  ) {
    this.moduleConfig = this._configService.getSettings(moduleCode);
  }

  ngOnInit() {}

  downloadStations(exportFormat: string) {
    this._occHabDataService.exportStations(
      exportFormat,
      this.storeService.idsStation
    );
  }
}
