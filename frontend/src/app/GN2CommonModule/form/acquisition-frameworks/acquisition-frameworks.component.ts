import { Component, OnInit, Input } from '@angular/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';

@Component({
  selector: 'pnx-acquisition-frameworks',
  templateUrl: './acquisition-frameworks.component.html'
})
export class AcquisitionFrameworksComponent extends GenericFormComponent implements OnInit {
  @Input() acquisitionFrameworks: Observable<Array<any>>;

  constructor(private _dfs: DataFormService) {
    super();
  }

  ngOnInit() {
    this.getAcquisitionFrameworks();
  }

  getAcquisitionFrameworks() {
    this.acquisitionFrameworks = this._dfs.getAcquisitionFrameworks()
                                          .pipe(
                                            map(data=>{
                                              const c = new Intl.Collator();
                                              return data.sort((a,b)=> c.compare(a.acquisition_framework_name, b.acquisition_framework_name));
                                            })
                                          )
  }
}
