import { Component, OnInit, Input } from '@angular/core';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';
import { DataFormService } from '../data-form.service';
import { FormControl } from '@angular/forms';

@Component({
  selector: 'pnx-municipalities',
  templateUrl: './municipalities.component.html',
  styleUrls: ['./municipalities.component.scss']
})
export class MunicipalitiesComponent implements OnInit {
  public municipalities: Array<any>;
  @Input() parentFormControl: FormControl;
  @Input() label: string;
  @Input() disabled: boolean;
  constructor(private _dfs: DataFormService) {}

  ngOnInit() {
    this._dfs.getMunicipalities().subscribe(data => {
      this.municipalities = data;
    });

    this.parentFormControl.valueChanges
      .filter(value => value >= 3)
      .distinctUntilChanged()
      .subscribe(value => {
        console.log('changeeelelelelel');
        this._dfs.getMunicipalities(value).subscribe(municipalities => {
          this.municipalities = municipalities;
        });
      });
  }
}
