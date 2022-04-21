import { Component, OnInit, Input } from '@angular/core';
import { DataFormService } from '../data-form.service';
import { FormControl } from '@angular/forms';
import { CommonService } from '@geonature_common/service/common.service';
import { Observable } from 'rxjs';

@Component({
  selector: 'pnx-municipalities',
  templateUrl: './municipalities.component.html',
  styleUrls: ['./municipalities.component.scss'],
})
export class MunicipalitiesComponent implements OnInit {
  @Input() parentFormControl: FormControl;
  @Input() label: string;
  /**
   * @deprecated Do not use this input
   */
  @Input() searchBar = false;
  @Input() disabled: boolean;
  @Input() valueFieldName: string = 'id_area'; // Field name for value (default : id_area)

  /**
   * @deprecated Do not use this input
   */
  @Input() bindAllItem: false;
  /**
   * @deprecated Do not use this input
   */ @Input() debounceTime: number;
  constructor(private _dfs: DataFormService, private _commonService: CommonService) {}

  ngOnInit() {}
}
