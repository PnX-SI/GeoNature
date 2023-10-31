import { Component, OnInit, Input } from '@angular/core';
import { UntypedFormControl } from '@angular/forms';
import { Individual } from './interfaces';
import { IndividualsService } from './individuals.service';

@Component({
  selector: 'pnx-individuals',
  templateUrl: './individuals.component.html',
  styleUrls: ['./individuals.component.scss'],
})
export class IndividualsComponent implements OnInit {
  @Input() parentFormControl: UntypedFormControl;
  @Input() idModule: number;
  @Input() label: string;

  keyLabel: string = 'individual_name';
  keyValue: string = 'id_individual';
  values: Individual[] = [];

  constructor(private _individualsService: IndividualsService) {}
  ngOnInit(): void {
    this._individualsService.getIndividuals(this.idModule).subscribe((data) => {
      this.values = data;
    });
  }
}
