import { Component, OnInit } from "@angular/core";
import { ActivatedRoute, Router } from "@angular/router";
import { Subscription } from "rxjs/Subscription";
import { ContactFormService } from "../contact-map-form/form/contact-form.service";
import { MapService } from "@geonature_common/map/map.service";
import { DataFormService } from "@geonature_common/form/data-form.service";
import { FormGroup, FormArray, FormControl } from "@angular/forms";
import { ContactService } from "../services/contact.service";
import { OccTaxConfig } from "../occtax.config";

@Component({
  selector: "pnx-contact-map-info",
  templateUrl: "contact-map-info.component.html",
  styleUrls: ["./contact-map-info.component.scss"]
})
export class ContactMapInfoComponent implements OnInit {
  private _sub: Subscription;
  public id: number;
  public occtaxConfig = OccTaxConfig;
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
  constructor(
    public fs: ContactFormService,
    private _route: ActivatedRoute,
    private _ms: MapService,
    private _dfs: DataFormService,
    private _router: Router,
    private _contactService: ContactService
  ) {}

  ngOnInit() {
    // init forms
    this.releveForm = this.fs.initReleveForm();
    this.occurrenceForm = this.fs.initOccurenceForm();
    // load nomenclatures
    this.loadNomenclaturesOccurrence();

    this._sub = this._route.params.subscribe(params => {
      this.id = +params["id"];
      if (!isNaN(this.id)) {
        // load one releve
        this._contactService.getOneReleve(this.id).subscribe(data => {
          this.userReleveCruved = data.cruved;

          this.releveForm.patchValue(data.releve);
          this.releve = data.releve;
          if (!OccTaxConfig.form_fields.releve.observers_txt) {
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
          data.releve.properties.t_occurrences_contact.forEach(occ => {
            this._dfs.getTaxonInfo(occ.cd_nom).subscribe(taxon => {
              occ["taxon"] = taxon;
              this.showSpinner = false;
            });
          });
        });
      }
    });
  }

  selectOccurrence(occ, index) {
    this.selectedIndex = index;
    this.selectedOccurrence = occ;
    this.occurrenceForm.patchValue(occ);
    // init counting form with data
    this.countingFormArray = this.fs.initCountingArray(
      occ.cor_counting_contact
    );
  }

  loadNomenclaturesOccurrence() {
    this._dfs
      .getNomenclatures(100, 14, 7, 13, 8, 101, 15)
      .subscribe(data => {});
  }
}
