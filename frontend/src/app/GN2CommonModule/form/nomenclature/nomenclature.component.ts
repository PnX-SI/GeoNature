import {
  Component,
  OnInit,
  Input,
  OnChanges,
  OnDestroy,
  SimpleChanges,
  ViewEncapsulation,
  Output,
  EventEmitter,
} from '@angular/core';
import { DataFormService } from '../data-form.service';
import { TranslateService, LangChangeEvent } from '@ngx-translate/core';
import { Subscription } from 'rxjs';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';
import { customSearchFn } from '@geonature/utils/ng-select-searchFn';

/**
 * Ce composant permet de créer un "input" de type "select" ou "multiselect" à partir d'une liste d'items définie dans le référentiel de nomenclatures
 * (thésaurus) de GeoNature (table ``ref_nomenclature.t_nomenclature``).
 *
 * En mode "multiselect" (Input ``multiSelect=true``), une barre de recherche permet de filtrée les nomenclatures sur leur label.
 *
 * NB: La table ``ref_nomenclatures.cor_taxref_nomenclature`` permet de faire corespondre des items de nomenclature à des groupe INPN et des règne. A chaque fois que ces deux derniers input sont modifiés, la liste des items est rechargée.
 * Ce composant peut ainsi être couplé au composant taxonomy qui renvoie le regne et le groupe INPN de l'espèce saisie.
 *
 * @example
 * <pnx-nomenclature
 * [parentFormControl]="occtaxForm.controls.id_nomenclature_etat_bio"
 * codeNomenclatureType="ETA_BIO"
 * [multiSelect]=true
 *  keyValue='cd_nomenclature'
 *  regne="Animalia"
 * group2Inpn="Mammifères">
 * </pnx-nomenclature>
 */
@Component({
  selector: 'pnx-nomenclature',
  templateUrl: './nomenclature.component.html',
  styleUrls: ['./nomenclature.component.scss'],
  encapsulation: ViewEncapsulation.None,
})
export class NomenclatureComponent
  extends GenericFormComponent
  implements OnInit, OnChanges, OnDestroy
{
  public labels: Array<any>;
  public labelLang: string;
  public definitionLang: string;
  public subscription: Subscription;
  public valueSubscription: Subscription;
  public currentCdNomenclature = 'null';
  public currentIdNomenclature: number;
  public savedLabels;
  /**
   * Mnémonique du type de nomenclature qui doit être affiché dans la liste déroulante.
   *  Table``ref_nomenclatures.bib_nomenclatures_types`` (obligatoire)
   */
  @Input() codeNomenclatureType: string;
  /**
   * Filter par regne taxonomique
   */
  @Input() regne: string;
  /**
   * Filter group 2 INPN
   */
  @Input() group2Inpn: string;
  /**
   * Attribut de l'objet nomenclature renvoyé au formControl (facultatif, par défaut ``id_nomenclature``).
   * Valeur possible: n'importequel attribut de l'objet ``nomenclature`` renvoyé par l'API
   */
  @Input() keyValue = 'id_nomenclature';

  @Input() bindAllItem: false;
  @Input() cdNomenclatures: Array<string> = [];
  @Output() labelsLoaded = new EventEmitter<Array<any>>();

  constructor(
    private _dfService: DataFormService,
    private _translate: TranslateService
  ) {
    super();
  }

  ngOnInit() {
    this.keyValue = this.bindAllItem ? null : this.keyValue || 'id_nomenclature'; // patch pour les cas ou this.keyValue == undefined
    this.labelLang = 'label_' + this._translate.currentLang;
    this.definitionLang = 'definition_' + this._translate.currentLang;
    // load the data
    this.initLabels();
    // subscrib to the language change
    this.subscription = this._translate.onLangChange.subscribe((event: LangChangeEvent) => {
      this.labelLang = 'label_' + this._translate.currentLang;
      this.definitionLang = 'definition_' + this._translate.currentLang;
    });

    // set cdNomenclature
    this.valueSubscription = this.parentFormControl.valueChanges.subscribe((id) => {
      this.currentIdNomenclature = id;
      const self = this;
      if (this.labels) {
        this.labels.forEach((label) => {
          if (this.currentIdNomenclature === label.id_nomenclature) {
            self.currentCdNomenclature = label.cd_nomenclature;
          }
        });
      }
    });
  }

  getCdNomenclature() {
    let cdNomenclature;
    if (this.labels) {
      this.labels.forEach((label) => {
        if (this.currentIdNomenclature === label.id_nomenclature) {
          cdNomenclature = label.cd_nomenclature;
        }
      });
      return cdNomenclature;
    }
  }

  ngOnChanges(changes: SimpleChanges) {
    // if change regne => change groupe2inpn also
    if (changes.regne !== undefined && !changes.regne.firstChange) {
      this.initLabels();
    }
    // if only change groupe2inpn
    if (
      changes.regne === undefined &&
      changes.group2Inpn !== undefined &&
      !changes.group2Inpn.firstChange
    ) {
      this.initLabels();
    }
  }

  initLabels() {
    const filters = { orderby: 'label_default', cd_nomenclature: this.cdNomenclatures };
    this._dfService
      .getNomenclature(this.codeNomenclatureType, this.regne, this.group2Inpn, filters)
      .subscribe((data) => {
        this.labels = data.values;
        this.savedLabels = data.values;
        this.labelsLoaded.emit(this.labels);
      });
  }

  //upgrade la fonction de recherche de ng-select
  searchFn(term, item) {
    return customSearchFn(term, item, this.labelLang);
  };

  ngOnDestroy() {
    this.subscription.unsubscribe();
    this.valueSubscription.unsubscribe();
  }

  filterItems(event) {
    if (this.searchBar && event) {
      this.labels = this.savedLabels.filter((el) => {
        const isIn = el.label_default.toUpperCase().indexOf(event.toUpperCase());
        return isIn !== -1;
      });
    }
  }
}
