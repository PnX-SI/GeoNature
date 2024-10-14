import { Component, Input, Output } from '@angular/core';
import { ImportDataService } from '../../services/data.service';
import { Destination } from '../../models/import.model';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';
import { EventEmitter } from '@angular/core';

@Component({
  selector: 'pnx-destinations',
  templateUrl: './destinations.component.html',
  styleUrls: ['./destinations.component.scss'],
})
export class DestinationsComponent extends GenericFormComponent {
  destinations: Array<Destination>;

  @Input() bindValue: string = 'code';
  @Input() displayAllowed: boolean = false; // To show only the destination for the current user
  @Output() onClear = new EventEmitter<any>();

  constructor(private _ds: ImportDataService) {
    super();
  }
  ngOnInit() {
    this.getDestinations();
  }

  getDestinations() {
    const method = this.displayAllowed
      ? this._ds.getAllowedDestinations()
      : this._ds.getDestinations();
    method.subscribe((destinations) => {
      this.destinations = destinations;
    });
  }
}
