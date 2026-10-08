import { Component, Input, OnInit, ViewEncapsulation } from '@angular/core';
import { Observable } from 'rxjs';
import { DataFormService } from '../data-form.service';
import { SelectFormComponent } from '../select-form.component';

/**
 * Ce composant permet de sélectionner un ou plusieurs organismes (table ``utilisateurs.bib_organismes``).
 * Renvoie l'objet: ```{
    "id_organisme": 1,
    "uuid_organisme": "...",
    "nom_organisme": "Parc national des Écrins"
  }
  ```
 * (ou uniquement la propriété indiquée dans ``bindValue``, par ex. ``id_organisme``).
 *
 * Deux rendus sont disponibles avec ``appearance`` : ``ng-select`` (défaut) ou ``material``.
 * Avec ``[autocomplete]="true"``, les organismes ne sont
 * pas tous chargés : ils sont demandés à l'API au fur et à mesure de la saisie
 * (recherche insensible à la casse et aux accents).
 */
@Component({
  selector: 'pnx-organism',
  templateUrl: './organism.component.html',
  styleUrls: ['../select-form.component.scss'],
  encapsulation: ViewEncapsulation.None,
})
export class OrganismComponent extends SelectFormComponent implements OnInit {
  /** Propriété de l'organisme renvoyée par le formulaire, l'objet entier si ``null``. */
  @Input() bindValue: string = null;
  @Input() compareWith = (c1, c2) => c1.id_organisme === c2.id_organisme;
  /** Liste des organismes à proposer. Tous les organismes par défaut. */
  @Input() organisms: Observable<any[]>;

  constructor(private _dfService: DataFormService) {
    super();
  }

  ngOnInit() {
    this.minSearchLength = 1;
    this.placeHolder ??= this.label;
    if (!this.organisms && !this.isRemote) {
      this.organisms = this._dfService.getOrganisms();
    }
    super.ngOnInit();
  }

  protected allItems(): Observable<any[]> {
    return this.organisms;
  }

  protected fetch(term: string): Observable<any[]> {
    return this._dfService.getOrganisms(true, { name: term, limit: this.searchLimit });
  }

  protected itemId(item: any) {
    return item.id_organisme;
  }

  itemLabel(item: any): string {
    return item?.nom_organisme ?? '';
  }
}
