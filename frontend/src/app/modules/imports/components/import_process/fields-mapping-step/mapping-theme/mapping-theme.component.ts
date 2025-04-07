import { Component, Input, OnInit } from '@angular/core';
import { FieldMappingService } from '@geonature/modules/imports/services/mappings/field-mapping.service';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule } from '@angular/forms';
import { FieldMappingInputComponent } from './fieldmapping-input/fieldmapping-input.component';
import { NgbModule } from '@ng-bootstrap/ng-bootstrap';
@Component({
  standalone: true,
  selector: 'pnx-mapping-theme',
  templateUrl: './mapping-theme.component.html',
  styleUrls: ['./mapping-theme.component.scss'],
  imports: [CommonModule, ReactiveFormsModule, FieldMappingInputComponent, NgbModule],
})
export class MappingThemeComponent {
  @Input() themeData;
  @Input() sourceFields: Array<string>;
  @Input() entity;

  constructor(public fm: FieldMappingService) {}
}
