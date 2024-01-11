import { Component, Input } from '@angular/core';
import { DataService } from '../../services/data.service';
import { Destination } from '../../models/import.model';
import { GenericFormComponent } from '@geonature_common/form/genericForm.component';

@Component({
  selector: 'pnx-destinations',
  templateUrl: './destinations.component.html',
  styleUrls: ['./destinations.component.scss']
})
export class DestinationsComponent extends GenericFormComponent {

  destinations: Array<Destination>;

  @Input() bindValue: string = 'code';

  constructor(private _ds: DataService) {
    super();
  }
  ngOnInit() {
    this.getDestinations();
  }

  getDestinations() {
    this._ds.getDestinations().subscribe((destinations) => {
      this.destinations = destinations;
    });
  }
}
