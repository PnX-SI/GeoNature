import {
  Component,
  OnInit,
  HostListener,
  Inject,
  AfterViewInit,
} from "@angular/core";
import { DOCUMENT } from "@angular/common";
import { MatDialog, MatDialogConfig } from "@angular/material";
import { ActivatedRoute, Router } from "@angular/router";
import { CommonService } from "@geonature_common/service/common.service"
import { ModuleConfig } from "../module.config";
import { OcctaxFormService } from "./occtax-form.service";
import { MapService } from "@geonature_common/map/map.service";
import { OcctaxFormParamDialog } from "./form-param/form-param.dialog";
import { OcctaxFormParamService } from "./form-param/form-param.service";
import { ConfirmationDialog } from "@geonature_common/others/modal-confirmation/confirmation.dialog";
import { OcctaxFormReleveService } from "./releve/releve.service";
import { OcctaxFormCountingService } from "./counting/counting.service";
import { OcctaxFormOccurrenceService } from "./occurrence/occurrence.service";
import { OcctaxTaxaListService } from "./taxa-list/taxa-list.service";
import { OcctaxDataService } from "../services/occtax-data.service";
import { OcctaxFormMapService } from "../occtax-form/map/map.service";
@Component({
  selector: "pnx-occtax-form",
  templateUrl: "./occtax-form.component.html",
  styleUrls: ["./occtax-form.component.scss"],
  // le composant doit initié les services suivants pour le bon fonctionnemment du formulaire
  // et le rechargemernt des données
  providers: [
    OcctaxTaxaListService,
    OcctaxFormService,
    OcctaxFormMapService,
    OcctaxFormReleveService,
    OcctaxFormCountingService,
    OcctaxFormOccurrenceService,
  ],
})
export class OcctaxFormComponent implements OnInit, AfterViewInit {
  public occtaxConfig = ModuleConfig;
  public id;
  public disableCancel = false;
  releveUrl: string = null;
  currentTab: "releve" | "taxons";
  cardHeight: number;
  cardContentHeight: any;

  constructor(
    @Inject(DOCUMENT) document,
    public dialog: MatDialog,
    private _route: ActivatedRoute,
    private _router: Router,
    public occtaxFormService: OcctaxFormService,
    private _mapService: MapService,
    public occtaxFormParamService: OcctaxFormParamService,
    private occtaxFormReleveService: OcctaxFormReleveService,
    private occtaxFormOccurrenceService: OcctaxFormOccurrenceService,
    private occtaxTaxaListService: OcctaxTaxaListService,
    private _ds: OcctaxDataService,
    private _commonService: CommonService
  ) { }

  ngOnInit() {
    //si modification, récuperation de l'ID du relevé
    let id = this._route.snapshot.paramMap.get("id");
    if (id && Number.isInteger(Number(id))) {
      this.occtaxFormService.id_releve_occtax.next(Number(id));
    } else {
      id = null;
      this.occtaxFormService.id_releve_occtax.next(null);
    }

    //gestion de la route pour les occurrences
    let urlSegments = this._router.routerState.snapshot.url.split("/");
    if (urlSegments[urlSegments.length - 1] === "taxons") {
      this.currentTab = <"releve" | "taxons">urlSegments.pop();
    } else {
      this.currentTab = "releve";
    }
    this.releveUrl = urlSegments.join("/");

    //Vérification de la route taxons avec un ID de releve, sinon redirection
    if (this.currentTab === "taxons" && id === null) {
      this._router.navigate([this.releveUrl]);
    }
  }



  ngAfterViewInit() {
    setTimeout(() => this.calcCardContentHeight(), 500);
  }

  @HostListener("window:resize", ["$event"])
  onResize(event) {
    this.calcCardContentHeight();
  }

  calcCardContentHeight() {
    let minusHeight = <HTMLScriptElement>(
      (<any>document.querySelector("pnx-occtax-form .tab"))
    )
      ? (<HTMLScriptElement>(
        (<any>document.querySelector("pnx-occtax-form .tab"))
      )).offsetHeight
      : 0;

    this.cardContentHeight = this._commonService.calcCardContentHeight(minusHeight + 20)

    // resize map after resize container
    if (this._mapService.map) {
      setTimeout(() => {
        this._mapService.map.invalidateSize();
      }, 10);
    }
  }

  openParametersDialog(): void {
    const dialogConfig = new MatDialogConfig();

    dialogConfig.data = {};
    dialogConfig.maxHeight = window.innerHeight - 20 + "px";
    dialogConfig.position = { top: "30px" };

    const dialogRef = this.dialog.open(OcctaxFormParamDialog, dialogConfig);
  }
  /**
   *
   * @param cancel : boolean. Action vient du bouton annuler = true, sinon false
   */
  leaveTheForm(cancel) {
    this.disableCancel = true;
    const url = this.occtaxFormService.chainRecording
      ? ["/occtax/form"]
      : ["/occtax"];

    // si le formulair est en cour d'édition
    if (
      (this.currentTab === "releve" &&
        this.occtaxFormReleveService.releveForm.dirty) ||
      (this.currentTab === "taxons" &&
        this.occtaxFormOccurrenceService.form.dirty)
    ) {
      //si un des 2 formulaires a été modifié mais non sauvegardé
      const message =
        "Êtes-vous sûr de vouloir fermer le formulaire ?<br>Des modifications non sauvegardées seront perdues.";
      const dialogRef = this.dialog.open(ConfirmationDialog, {
        width: "auto",
        position: { top: "5%" },
        data: { message: message },
      });

      dialogRef.afterClosed().subscribe((result) => {
        if (result) {
          if (this.occtaxFormService.chainRecording) {
            this.currentTab = "releve";
          }
          if (cancel) {
            this.deleteReleveIfNoOcc();
          }
          this._router.navigate(url);
          this.occtaxTaxaListService.cleanOccurrenceInProgress();
        }
      });
    } else {
      if (this.occtaxFormService.chainRecording) {
        this.currentTab = "releve";
      }
      if (cancel) {
        this.deleteReleveIfNoOcc();
      }
      this._router.navigate(url);
      this.occtaxTaxaListService.cleanOccurrenceInProgress();
    }
  }

  /** Action sur le bouton annuler
   * Redirige vers la liste occtax
   * Si aucun taxon saisi, alors on supprime le releve
   */
  deleteReleveIfNoOcc() {
    const occ = this.occtaxTaxaListService.occurrences$.getValue();
    if (occ.length === 0) {
      this._ds
        .deleteReleve(this.occtaxFormService.id_releve_occtax.getValue())
        .subscribe((d) => { });
    }
  }
}
