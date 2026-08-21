import { Component, OnInit, Input } from '@angular/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';
import { PublicationsService } from '../../services/publication.service';

/**
 * This component allows to create a "select" or "multiselect" input displaying all publications
 * @example
 * <pnx-publications-select
 * [multiSelect]='true'
 * [parentFormControl]="formService.searchForm.controls.id_publications"
 * label="{{ 'MetaData.Publications.Publications' | translate}}"
 * </pnx-publications-select>
 */

@Component({
  selector: 'pnx-publications-select',
  templateUrl: './publications-select.component.html',
})
export class PublicationsSelectComponent extends GenericFormComponent implements OnInit {
  @Input() publications: Observable<Array<any>>;
  protected isLoading: Boolean = true;

  constructor(private _publicationsService: PublicationsService) {
    super();
  }

  ngOnInit() {
    super.ngOnInit();
    this.getPublications();
  }

  getPublications() {
    this.publications = this._publicationsService.searchFromFirstPage().pipe(
      map((data) => {
        const c = new Intl.Collator();
        return data.sort((a, b) => c.compare(a.publication_reference, b.publication_reference));
      }),
      map((sortedData) => {
        this.isLoading = false;
        return sortedData;
      })
    );
  }
}
