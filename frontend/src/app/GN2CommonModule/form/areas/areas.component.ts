import { Component, OnInit, Input } from '@angular/core';
import { DataFormService } from '../data-form.service';
import { FormControl } from '@angular/forms';

@Component({
  selector: 'pnx-areas',
  templateUrl: 'areas.component.html'
})
export class AreasComponent implements OnInit {
  public areas: any;
  @Input() idType: number; // Areas id_type
  @Input() label: string;
  @Input() searchBar = false;
  @Input() parentFormControl: FormControl;
  @Input() bindAllItem: false;
  @Input() debounceTime: number;
  constructor(private _dfs: DataFormService) {}

  ngOnInit() {
    console.log('areaaaaaaaaaaaas', this.idType);
    this._dfs.getAreas(this.idType).subscribe(data => (this.areas = data));
  }

  refreshAreas(area_name) {
    this._dfs.getAreas(this.idType, area_name).subscribe(data => (this.areas = data));
  }
}
