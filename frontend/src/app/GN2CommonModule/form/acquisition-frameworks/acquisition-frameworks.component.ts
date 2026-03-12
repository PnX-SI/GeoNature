import { Component, OnInit, Input } from '@angular/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';

/**
 *  Ce composant permet de créer un "input" de type "select" ou "multiselect" affichant l'ensemble des cadres d'acquisition sur lesquels l'utilisateur connecté a des droits (table ``gn_meta.t_acqusitions_framework`` et ``gn_meta.cor_acquisition_framework_actor``)
 * @example
 * <pnx-acquisition-frameworks
 * [multiSelect]='true'
 * [parentFormControl]="formService.searchForm.controls.id_acquisition_frameworks"
 * label="{{ 'AcquisitionFramework' | translate}}"
 * </pnx-acquisition-frameworks>
 */

@Component({
  selector: 'pnx-acquisition-frameworks',
  templateUrl: './acquisition-frameworks.component.html',
})
export class AcquisitionFrameworksComponent extends GenericFormComponent implements OnInit {
  @Input() acquisitionFrameworks: Observable<Array<any>>;
  protected isLoading: Boolean = true;

  constructor(private _dfs: DataFormService) {
    super();
  }

  ngOnInit() {
    super.ngOnInit();
    this.getAcquisitionFrameworks();
  }

  getAcquisitionFrameworks() {
    this.acquisitionFrameworks = this._dfs.getAcquisitionFrameworksList({}, {}, 1, -1).pipe(
      map((data) => {
        const c = new Intl.Collator();
        return data.items.sort((a, b) =>
          c.compare(a.acquisition_framework_name, b.acquisition_framework_name)
        );
      }),
      map((sortedData) => {
        this.isLoading = false;
        return sortedData;
      })
    );
  }
}
