import { DesignStyle } from '../items-select/items-select.component';
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
import { Nomenclature } from '../../interfaces';
import { NomenclatureSource } from './nomenclature.source';
import { TranslateService, LangChangeEvent } from '@ngx-translate/core';
import { Subscription } from 'rxjs';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';
import { findCdNomenclature, langKey } from './nomenclature.utils';

/**
 * Ce composant (connecté à l'API, la partie affichage est dans ``pnx-items-select``) permet de créer un "input" de type "select" ou "multiselect" à partir d'une liste d'items définie dans le référentiel de nomenclatures
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
  public labels: Array<Nomenclature>;
  public labelLang: string;
  public definitionLang: string;
  public subscription: Subscription;
  public valueSubscription: Subscription;
  public currentCdNomenclature = 'null';
  public currentIdNomenclature: number;
  public savedLabels: Array<Nomenclature>;
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
   * Filter group 3 INPN
   */
  @Input() group3Inpn?: string;
  /**
   * Attribut de l'objet nomenclature renvoyé au formControl (facultatif, par défaut ``id_nomenclature``).
   * Valeur possible: n'importequel attribut de l'objet ``nomenclature`` renvoyé par l'API
   */
  @Input() keyValue = 'id_nomenclature';
  /** Design of the select, see ``pnx-items-select`` */
  @Input() designStyle: DesignStyle = 'material';

  @Input() bindAllItem: false;

  @Input() cdNomenclatures: Array<string> = [];

  @Output() labelsLoaded = new EventEmitter<Array<any>>();
  @Output() $currentCdNomenclature = new EventEmitter<string>();

  constructor(
    private _source: NomenclatureSource,
    private _translate: TranslateService
  ) {
    super();
  }

  /**
   * Match the items with the value of the control when whole items are written in the control
   * (``bindAllItem``): the stored items are not the loaded ones, so they are compared by id.
   */
  compareWith = (item: Nomenclature, selected: Nomenclature): boolean =>
    item?.id_nomenclature === selected?.id_nomenclature;

  ngOnInit() {
    super.ngOnInit();
    this.keyValue = this.bindAllItem ? null : this.keyValue || 'id_nomenclature'; // patch pour les cas ou this.keyValue == undefined
    this.labelLang = langKey('label', this._translate.currentLang);
    this.definitionLang = langKey('definition', this._translate.currentLang);
    // load the data
    this.initLabels();
    // subscrib to the language change
    this.subscription = this._translate.onLangChange.subscribe((event: LangChangeEvent) => {
      this.labelLang = langKey('label', this._translate.currentLang);
      this.definitionLang = langKey('definition', this._translate.currentLang);
    });

    // set cdNomenclature
    this.valueSubscription = this.parentFormControl.valueChanges.subscribe((id) => {
      this.emitCurrentCdNomenclature(id);
    });
  }

  private emitCurrentCdNomenclature(id: number) {
    this.currentIdNomenclature = id;
    if (this.labels) {
      this.currentCdNomenclature = findCdNomenclature(this.labels, id);
      this.$currentCdNomenclature.emit(this.currentCdNomenclature);
    }
  }

  getCdNomenclature() {
    if (this.labels) {
      return findCdNomenclature(this.labels, this.currentIdNomenclature) ?? undefined;
    }
  }

  ngOnChanges(changes: SimpleChanges) {
    super.ngOnChanges(changes);

    // if change regne => change groupe2inpn also
    if (changes.regne !== undefined && !changes.regne.firstChange) {
      this.initLabels();
    }
    // if only change groupe2inpn
    if (
      changes.regne === undefined &&
      changes.group2Inpn !== undefined &&
      !changes.group2Inpn.firstChange &&
      changes.group3Inpn !== undefined &&
      !changes.group3Inpn.firstChange
    ) {
      this.initLabels();
    }
  }

  initLabels() {
    this._source
      .load({
        codeNomenclatureType: this.codeNomenclatureType,
        regne: this.regne,
        group2Inpn: this.group2Inpn,
        group3Inpn: this.group3Inpn,
        cdNomenclatures: this.cdNomenclatures,
      })
      .subscribe((values) => {
        this.labels = values;
        this.savedLabels = values;
        this.labelsLoaded.emit(this.labels);
        this.emitCurrentCdNomenclature(this.parentFormControl.value);
      });
  }

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
