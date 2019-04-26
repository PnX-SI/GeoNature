import { Component, Input, ViewEncapsulation } from '@angular/core';
import { DataFormService } from '../data-form.service';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';

@Component({
  selector: 'pnx-observers',
  templateUrl: './observers.component.html',
  styleUrls: ['./observers.component.scss'],
  encapsulation: ViewEncapsulation.None
})
export class ObserversComponent extends GenericFormComponent {
  @Input() idMenu: number;
  @Input() bindAllItem = false;
  @Input() bindValue: string = null;

  public observers: Observable<Array<any>>;

  constructor(private _dfService: DataFormService) {
    super();
  }

  ngOnInit() {
    this.observers = this._dfService
                          .getObservers(this.idMenu)
                          .pipe(
                            map(data => data)
                          );
  }
}
