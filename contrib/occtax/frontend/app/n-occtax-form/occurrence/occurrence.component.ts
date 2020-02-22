import { Component, OnInit } from "@angular/core";
import { animate, state, style, transition, trigger } from '@angular/animations';
import { FormControl, FormGroup } from "@angular/forms";
import { map, filter, tap } from 'rxjs/operators';
import { OcctaxFormService } from "../occtax-form.service";
import { CommonService } from "@geonature_common/service/common.service";
import { NomenclatureComponent } from "@geonature_common/form/nomenclature/nomenclature.component";
import { ModuleConfig } from "../../module.config";
import { OcctaxFormOccurrenceService } from "./occurrence.service";
import { Taxon } from "@geonature_common/form/taxonomy/taxonomy.component";

@Component({
  selector: "pnx-occtax-form-occurrence",
  templateUrl: "./occurrence.component.html",
  styleUrls: ["./occurrence.component.scss"],
  animations: [
    trigger('detailExpand', [
      state('collapsed', style({height: '0px', minHeight: '0', margin: '-1px', overflow: 'hidden', padding: '0', display:'none'})),
      state('expanded', style({height: '*'})),
      transition('expanded <=> collapsed', animate('225ms cubic-bezier(0.4, 0.0, 0.2, 1)')),
    ]),
  ],
})
export class OcctaxFormOccurrenceComponent implements OnInit {
  
  // @Input() occurrenceForm: FormGroup;
  // @ViewChild("taxon") taxon;
  // @ViewChildren(NomenclatureComponent)
  // nomenclatures: QueryList<NomenclatureComponent>;
  // @ViewChild("existProof") existProof: NomenclatureComponent;
  public occtaxConfig = ModuleConfig;
  public occurrenceForm: FormGroup;
  public taxonForm: FormControl; //control permettant de rechercher un taxon TAXREF
  private advanced: string = 'collapsed';

  constructor(
    public fs: OcctaxFormService,
    private _commonService: CommonService,
    private occtaxFormOccurrenceService: OcctaxFormOccurrenceService
  ) {}

  ngOnInit() {
    this.occurrenceForm = this.occtaxFormOccurrenceService.form;

    this.initTaxrefSearch();
  }

  initTaxrefSearch() {
    this.taxonForm = new FormControl(null);

    //attribut le cd_nom au formulaire si un taxon est selectionné
    this.taxonForm
          .valueChanges
          .pipe(
            filter(taxon=>taxon !== null),
            map(taxon=>{
              let nom_cite = null;
              let cd_nom = null;
              if (typeof taxon === 'string') {
                nom_cite = taxon.length ? taxon : null;
              } else {
                nom_cite = taxon.search_name.replace(/<[^>]*>/g, '');
                cd_nom = taxon.cd_nom ? taxon.cd_nom : null;
              }
              return {
                        nom_cite: nom_cite, 
                        cd_nom: cd_nom
                      };
            })
          )
          .subscribe((values: any)=>{
            this.occurrenceForm.get('nom_cite').setValue(values.nom_cite);
            this.occurrenceForm.get('cd_nom').setValue(values.cd_nom);
          });

    this.occtaxFormOccurrenceService.occurrence
              .pipe(
                tap(()=>this.taxonForm.setValue(null)),
                filter(occurrence=>occurrence),
                map((occurrence: any): Taxon=>{
                  let taxon: Taxon = occurrence.taxref ? <Taxon> occurrence.taxref : <Taxon> {};
                  taxon.search_name = occurrence.nom_cite.replace(/<[^>]*>/g, '');
                  return taxon
                })
              )
              .subscribe((taxref: Taxon)=>this.taxonForm.setValue(taxref));
  }

  getLabels(labels) {
    //this.fs.currentExistProofLabels = labels;
  }

  validateDigitalProof(c: FormControl) {
    // let REGEX = new RegExp("^(http://|https://|ftp://){1}.+$");
    // return REGEX.test(c.value)
    //   ? null
    //   : {
    //       validateDigitalProof: {
    //         valid: false
    //       }
    //     };
  }

  collapse(){
    this.advanced = (this.advanced === 'collapsed' ? 'expanded' : 'collapsed');
  }
}
