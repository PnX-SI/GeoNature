import { Component, OnInit, AfterViewInit } from "@angular/core";
import { ActivatedRoute, Router } from "@angular/router";
import { Subscription, BehaviorSubject } from "rxjs";
import { map, filter, tap } from "rxjs/operators";
import { isEqual } from "lodash";
import { MapService } from "@geonature_common/map/map.service";
import { OcctaxDataService } from "../services/occtax-data.service";
import { ModuleConfig } from "../module.config";
import { NgbModal } from "@ng-bootstrap/ng-bootstrap";
import { CommonService } from "@geonature_common/service/common.service";
import { MediaService } from "@geonature_common/service/media.service";
import { DataFormService } from "@geonature_common/form/data-form.service";

const NOMENCLATURES = [
  "TECHNIQUE_OBS",
  "TYP_GRP",
  "METH_DETERMIN",
  "STATUT_OBS",
  "METH_OBS",
  "ETA_BIO",
  "NATURALITE",
  "STATUT_BIO",
  "STATUT_SOURCE",
  "NIV_PRECIS",
  "DEE_FLOU",
  "PREUVE_EXIST",
  "STADE_VIE",
  "SEXE",
  "OBJ_DENBR",
  "TYP_DENBR",
  "NAT_OBJ_GEO",
  "OCC_COMPORTEMENT"
];

@Component({
  selector: "pnx-occtax-map-info",
  templateUrl: "occtax-map-info.component.html",
  styleUrls: ["./occtax-map-info.component.scss"],
})
export class OcctaxMapInfoComponent implements OnInit, AfterViewInit {
  public occtaxConfig = ModuleConfig;
  public occtaxData: BehaviorSubject<any> = new BehaviorSubject(null);
  nomenclatures: Array<any> = [];
  public cardHeight: number;
  displayOccurrence: BehaviorSubject<any> = new BehaviorSubject(null);
  private _geojson: any;
  public userReleveCruved: any;

  get releve() {
    return this.occtaxData.getValue()
      ? this.occtaxData.getValue().properties
      : null;
  }

  get id() {
    return this.occtaxData.getValue() ? this.occtaxData.getValue().id : null;
  }

  get geojson() {
    return this._geojson;
  }
  set geojson(geojson: any) {
    if (!isEqual(geojson, this._geojson)) {
      this._geojson = geojson;
    }
  }

  get occurrences() {
    return this.releve && this.releve.t_occurrences_occtax
      ? this.releve.t_occurrences_occtax
      : [];
  }

  get nbCounting() {
    let nbCounting = 0;
    for (var i = 0; i < this.occurrences.length; i++) {
      nbCounting = +this.occurrences[i].cor_counting_occtax.length;
    }
    return nbCounting;
  }

  constructor(
    private _route: ActivatedRoute,
    private _ms: MapService,
    private _router: Router,
    private occtaxDataService: OcctaxDataService,
    private _modalService: NgbModal,
    private _commonService: CommonService,
    private dataFormS: DataFormService,
    public ms: MediaService,
  ) { }

  ngOnInit() {
    //si modification, récuperation de l'ID du relevé
    let id = this._route.snapshot.paramMap.get("id");
    let id_counting = this._route.snapshot.paramMap.get("id_counting");

    if (id && Number.isInteger(Number(id))) {
      this.getOcctaxData(Number(id));
    } else if (id_counting && Number.isInteger(Number(id_counting))) {
      //si id_counting de passé
      this.occtaxDataService
        .getOneCounting(Number(id_counting))
        .pipe(map((data) => data["id_releve"]))
        .subscribe((id_releve) => {
          this.getOcctaxData(id_releve)
        });
    }

    this.getNomenclatures();
  }

  ngAfterViewInit() {
    //gestion de la geometrie
    this.occtaxData
      .pipe(
        filter((data) => data !== null),
        map((data) => {
          return { geometry: data.geometry };
        })
      )
      .subscribe((geojson) => {
        this.geojson = geojson;
        this._ms.loadGeometryReleve(geojson, false);
      });
    this.cardHeight = this._commonService.calcCardContentHeight(50);
    if (this._ms.map) {
      setTimeout(() => {
        this._ms.map.invalidateSize();
      }, 10);
    }
  }

  getOcctaxData(id) {
    this.occtaxDataService
      .getOneReleve(id)
      .pipe(
        map((data) => {
          this.userReleveCruved = data.cruved;
          let releve = data.releve;
          releve.properties.date_min = new Date(releve.properties.date_min);
          releve.properties.date_max = new Date(releve.properties.date_max);
          return releve;
        })
      )
      .subscribe(
        (data) => this.occtaxData.next(data),
        (error) => {
          this._commonService.translateToaster("error", "Releve.DoesNotExist");
          this._router.navigate(["occtax"]);
        }
      );
  }

  getNomenclatures() {
    this.dataFormS
      .getNomenclatures(NOMENCLATURES)
      .pipe(
        map((data) => {
          let values = [];
          for (let i = 0; i < data.length; i++) {
            data[i].values.forEach((element) => {
              values[element.id_nomenclature] = element;
            });
          }
          return values;
        })
      )
      .subscribe((nomenclatures) => (this.nomenclatures = nomenclatures));
  }

  getLibelleByID(ID: number, lang: string = "default") {
    return this.nomenclatures[ID]
      ? this.nomenclatures[ID][`label_${lang}`]
      : null;
  }

  openModalDelete(modalDelete) {
    this._modalService.open(modalDelete);
  }

  deleteReleve(modal) {
    this.occtaxDataService.deleteReleve(this.id).subscribe(
      () => {
        this._commonService.translateToaster(
          "success",
          "Releve.DeleteSuccessfully"
        );
        this._router.navigate(["/occtax"]);
      },
      (error) => {
        if (error.status === 403) {
          this._commonService.translateToaster("error", "NotAllowed");
        } else {
          this._commonService.translateToaster("error", "ErrorMessage");
        }
      }
    );
  }
}
