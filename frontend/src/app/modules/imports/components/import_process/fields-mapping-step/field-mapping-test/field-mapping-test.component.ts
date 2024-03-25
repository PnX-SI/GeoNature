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
  public sourceFields:Array<string> = [];
  public isReady:boolean=false;
  constructor(public _fieldMappingService: FieldMappingService) {}

  ngOnInit() {
    
    this._fieldMappingService.retrieveData().subscribe(({ fieldMappings, targetFields, sourceFields })=>{
      this._fieldMappingService.parseData({ fieldMappings, targetFields, sourceFields });
      this.targetFields = this._fieldMappingService.getTargetFieldsData();
      this.sourceFields = this._fieldMappingService.getSourceFieldsData()
      this._fieldMappingService.initForm();
      this._fieldMappingService.populateMappingForm();
      this.isReady = true;
    });
  }
}
