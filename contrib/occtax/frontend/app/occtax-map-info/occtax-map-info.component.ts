import { Component, OnInit } from "@angular/core";
import { ActivatedRoute, Router } from "@angular/router";
import { Subscription } from "rxjs/Subscription";
import { OcctaxFormService } from "../occtax-map-form/form/occtax-form.service";
import { MapService } from "@geonature_common/map/map.service";
import { DataFormService } from "@geonature_common/form/data-form.service";
import { FormGroup, FormArray } from "@angular/forms";
import { OcctaxDataService } from "../services/occtax-data.service";
import { ModuleConfig } from "../module.config";
import { NgbModal } from "@ng-bootstrap/ng-bootstrap";
import { CommonService } from "@geonature_common/service/common.service";

@Component({
  selector: "pnx-occtax-map-info",
  templateUrl: "occtax-map-info.component.html",
  styleUrls: ["./occtax-map-info.component.scss"],
  providers: [OcctaxFormService]
})
export class OcctaxMapInfoComponent implements OnInit {
  private _sub: Subscription;
  public id: number;
  public occtaxConfig = ModuleConfig;
  public releve: any;
  public observers: any;
  public selectedOccurrence: any;
  public occurrenceForm: FormGroup;
  public countingFormArray: FormArray;
  public disabled = true;
  public selectedIndex: number;
  public dateMin: string;
  public dateMax: string;
  public showSpinner = true;
  public geojson: any;
  public releveForm: FormGroup;
  public userReleveCruved: any;
  public nbCounting = 0;
  constructor(
    public fs: OcctaxFormService,
    private _route: ActivatedRoute,
    private _ms: MapService,
    private _dfs: DataFormService,
    private _router: Router,
    private _occtaxService: OcctaxDataService,
    private _modalService: NgbModal,
    private _commonService: CommonService
  ) {}

  ngOnInit() {
    // init forms
    this.releveForm = this.fs.initReleveForm();
    this.occurrenceForm = this.fs.initOccurenceForm();

    this._sub = this._route.params.subscribe(params => {
      // check if the id in the URL is an id_releve or a id_counting
      const inter = this._router.url.split("/");
      const parsed_url = inter[inter.length - 2];
      if (parsed_url === "id_counting") {
        // get the id_releve from the id_counting
        this._occtaxService.getOneCounting(params["id"]).subscribe(data => {
          this.id = data["id_releve"];
          this.loadReleve(this.id);
        });
      } else {
        // get the id_releve from the url
        this.id = +params["id"];
        this.loadReleve(this.id);
      }
    });
  }

  selectOccurrence(occ, index) {
    this.selectedIndex = index;
    this.selectedOccurrence = occ;
    this.occurrenceForm.patchValue(occ);
    // init counting form with data
    this.countingFormArray = this.fs.initCountingArray(occ.cor_counting_occtax);
  }

  loadReleve(id_releve) {
    if (!isNaN(id_releve)) {
      // load one releve
      this._occtaxService.getOneReleve(id_releve).subscribe(
        data => {
          this.userReleveCruved = data.cruved;
          // calculate the nbCounting
          data.releve.properties.t_occurrences_occtax.forEach(occ => {
            this.nbCounting += occ.cor_counting_occtax.length;
          });

          this.releveForm.patchValue(data.releve);
          this.releve = data.releve;
          if (!ModuleConfig.observers_txt) {
            this.observers = data.releve.properties.observers
              .map(obs => obs.nom_role + " " + obs.prenom_role)
              .join(", ");
          } else {
            this.observers = data.releve.properties.observers_txt;
          }
          this.dateMin = data.releve.properties.date_min.substring(0, 10);
          this.dateMax = data.releve.properties.date_max.substring(0, 10);

          this._ms.loadGeometryReleve(data.releve, false);

          // load taxonomy info
          data.releve.properties.t_occurrences_occtax.forEach(occ => {
            this._dfs.getTaxonInfo(occ.cd_nom).subscribe(taxon => {
              occ["taxon"] = taxon;
              this.showSpinner = false;
            });
          });
        },
        error => {
          if (error.status === 403) {
            this._commonService.translateToaster("error", "NotAllowed");
          } else if (error.status === 404) {
            this._commonService.translateToaster(
              "error",
              "Releve.DoesNotExist"
            );
          }

          this._router.navigate(["/occtax"]);
        }
      );
    }
  }

  openModalDelete(modalDelete) {
    this._modalService.open(modalDelete);
  }

  deleteReleve(modal) {
    this._occtaxService.deleteReleve(this.id).subscribe(
      () => {
        this._commonService.translateToaster(
          "success",
          "Releve.DeleteSuccessfully"
        );
        this._router.navigate(["/occtax"]);
      },
      error => {
        if (error.status === 403) {
          this._commonService.translateToaster("error", "NotAllowed");
        } else {
          this._commonService.translateToaster("error", "ErrorMessage");
        }
      }
    );
  }
}
