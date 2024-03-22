import { Component, OnInit } from '@angular/core';
import { ImportDataService } from '../../../../services/data.service';
import { FieldMappingService } from '@geonature/modules/imports/services/mappings/field-mapping.service';

@Component({
  selector: 'pnx-field-mapping-test',
  templateUrl: './field-mapping-test.component.html',
  styleUrls: ['./field-mapping-test.component.scss']
})
export class FieldMappingTestComponent implements OnInit {
  public targetFields;
  public isReady:boolean=false;
  constructor(public _fm: FieldMappingService) {}

  ngOnInit() {
    // subscribe(({ fieldMappings, targetFields, sourceFields }) => {
    
    this._fm.retrieveData().subscribe(({ fieldMappings, targetFields, sourceFields })=>{
      this._fm.parseData({ fieldMappings, targetFields, sourceFields });
      this.targetFields = this._fm.getTargetFieldsData();
      this._fm.initForm();
      this._fm.populateMappingForm();
      this.isReady = true;
    });
  }
}
