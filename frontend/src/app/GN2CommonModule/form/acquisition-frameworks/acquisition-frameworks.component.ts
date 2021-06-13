import { Component, OnInit, Input } from '@angular/core';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';

/**
 *  Ce composant permet de créer un "input" de type "select" ou "multiselect" affichant l'ensemble des cadres d'acquisition sur lesquels l'utilisateur connecté a des droits (table ``gn_meta.t_acqusitions_framework`` et ``gn_meta.cor_acquisition_framework_actor``)
 * @example
 * <pnx-acquisition-frameworks
 * [multiSelect]='true'
 * [displayAll]="true"
 * [parentFormControl]="formService.searchForm.controls.id_acquisition_frameworks"
 * label="{{ 'MetaData.AcquisitionFramework' | translate}}"
 * </pnx-acquisition-frameworks>
 */
@Component({
  selector: 'pnx-acquisition-frameworks',
  templateUrl: './acquisition-frameworks.component.html'
})
export class AcquisitionFrameworksComponent extends GenericFormComponent implements OnInit {
  public values: Array<any>;
  /**
   * Booléan qui permet de passer tout l'objet au formControl, et pas seulement une propriété de l'objet renvoyé par l'API.
   * Facultatif, par défaut à ``false``, c'est alors l'id_acquisition_frameworks qui est passé au formControl. Lorsque l'on passe ``true`` à cet Input, l'Input ``keyValue```devient inutile.
   */
  @Input() bindAllItem: false;
  public savedValues: Array<any>;
  constructor(private _dfs: DataFormService) {
    super();
  }

  ngOnInit() {
    this._dfs.getAcquisitionFrameworksForSelect().subscribe(data => {
      this.values = data;
      this.savedValues = data;
    });
  }

  filterItems(event) {
    this.values = super.filterItems(event, this.savedValues, 'acquisition_framework_name');
  }
}
