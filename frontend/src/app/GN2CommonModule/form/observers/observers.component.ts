import { Component, OnInit, Input, Output, EventEmitter, ViewEncapsulation } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { DataFormService } from '../data-form.service';

/**
 * Ce composant permet d'afficher un input de type "autocomplete" sur un liste d'observateur définit dans le schéma ``utilisateur.t_menus`` et ``utilisateurs.cor_role_menu``.
 * Il permet de séléctionner plusieurs utilisateurs dans le même input.
 * Renvoie l'objet: ```{
    "nom_complet": "ADMINISTRATEUR test",
    "nom_role": "Administrateur",
    "id_role": 1,
    "prenom_role": "test",
    "id_menu": 9
  }
  ```
 */
@Component({
  selector: 'pnx-observers',
  templateUrl: './observers.component.html',
  styleUrls: ['./observers.component.scss'],
  encapsulation: ViewEncapsulation.None
})
export class ObserversComponent implements OnInit {
  /**
   *  Id de la liste d'utilisateur (table ``utilisateur.t_menus``) (obligatoire)
   */
  @Input() idMenu: number;
  @Input() codeList: string;

  @Input() label: string;
  // Disable the input: default to false
  @Input() disabled = false;
  @Input() parentFormControl: FormControl;
  /** Booléan qui permet de passer tout l'objet au formControl, et pas seulement une propriété de l'objet renvoyé par l'API.
   * Facultatif, par défaut à ``false``, c'est alors l'id_role qui est passé au formControl. Lorsque l'on passe ``true`` à cet Input, l'Input ``keyValue`` devient inutile. */
  @Input() bindAllItem = false;
  // search bar default to true
  @Input() searchBar: boolean = true;
  @Output() onChange = new EventEmitter<any>();
  @Output() onDelete = new EventEmitter<any>();
  public searchControl = new FormControl();
  public observers: Array<any> = [];
  public filteredObservers: Array<any> = [];
  public selectedObservers = [];

  constructor(private _dfService: DataFormService) {}

  ngOnInit() {
    // si idMenu
    if (this.idMenu) {
      this._dfService.getObservers(this.idMenu).subscribe(data => {
        this.observers = data;
        this.filteredObservers = data;
        if (this.parentFormControl.value) {
          this.parentFormControl.setValue(this.parentFormControl.value);
        }
      });
      // sinon si codeList
    } else if (this.codeList) {
      this._dfService.getObserversFromCode(this.codeList).subscribe(data => {
        this.observers = data;
        this.filteredObservers = data;
        if (this.parentFormControl.value) {
          this.parentFormControl.setValue(this.parentFormControl.value);
        }
      });
    }
  }

  filterObservers(event) {
    if (event !== null && event.length > 0) {
      const regex = new RegExp(
        event
          .toLowerCase()
          .split(' ')
          .join('*|') + '*'
      );
      this.filteredObservers = this.observers.filter(obs => {
        return obs.nom_complet.toLowerCase().match(regex);
      });
    } else {
      this.filteredObservers = this.observers;
    }
  }

  formatobs(obs: string): string {
    return obs.toLowerCase().replace(' ', '');
  }
}
