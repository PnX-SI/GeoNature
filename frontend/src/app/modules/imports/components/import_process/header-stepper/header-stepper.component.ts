import { Component, OnInit } from '@angular/core';
import { Destination } from '@geonature/modules/imports/models/import.model';
import { ActivatedRoute } from '@angular/router';
import { ImportDataService } from '@geonature/modules/imports/services/data.service';

@Component({
  selector: 'header-stepper',
  styleUrls: ['header-stepper.component.scss'],
  templateUrl: 'header-stepper.component.html',
})
export class HeaderStepperComponent implements OnInit {
  private _destination: Destination | null;
  constructor(
    private _importDataService: ImportDataService,
    private _route: ActivatedRoute
  ) {}

  ngOnInit() {
    this._route.params.subscribe((params) => {
      this._importDataService.getDestination(params['destination']).subscribe((dest) => {
        this._destination = dest;
      });
    });
  }

  get destinationLabel(): string {
    return this._destination ? this._destination.label : '';
  }
}
