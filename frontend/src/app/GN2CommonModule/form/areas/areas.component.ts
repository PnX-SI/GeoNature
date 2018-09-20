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
    this._dfs.getAreas(this.idType).subscribe(data => (this.areas = data));
  }

  refreshAreas(area_name) {
    // refresh area API call only when area_name > 2 character
    if (area_name && area_name.length > 2) {
      this._dfs.getAreas(this.idType, area_name).subscribe(data => (this.areas = data));
    }
  }
}
