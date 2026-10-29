import { distinctUntilChanged } from 'rxjs/operators';
import { Component, OnInit, Input, Output, SimpleChanges, EventEmitter } from '@angular/core';
import { CruvedStoreService } from '@geonature_common/service/cruved-store.service';
import { HttpClient } from '@angular/common/http';
import { DataFormService } from '@geonature_common/form/data-form.service';
import { ImportDataService } from '@geonature/modules/imports/services/data.service';

@Component({
  selector: 'pnx-import-button',
  templateUrl: 'import-button.component.html',
  styleUrls: ['./import-button.component.css'],
  // ImportDataService is only provided by the lazy-loaded ImportsModule, and is stateful
  // (current destination): give the button its own instance
  providers: [ImportDataService],
})
export class ImportButtonComponent implements OnInit {
  public canImport: boolean = false;
  @Input() moduleCode: string = 'generic';
  @Input() objectType: string = 'ALL';
  @Input() properties: any = {};

  constructor(
    public _cruvedStore: CruvedStoreService,
    private _ids: ImportDataService
  ) {}

  ngOnInit() {
    this._ids.getDestinations('C', { module_code: this.moduleCode }).subscribe((data) => {
      if (data.length == 0) {
        this.canImport = false;
      } else {
        const userCruved =
          this._cruvedStore.cruved[this.moduleCode].module_objects[this.objectType].cruved;

        let cruvedImport: any = {};
        if (this._cruvedStore.cruved.IMPORT) {
          cruvedImport = this._cruvedStore.cruved.IMPORT.module_objects.IMPORT.cruved;
        }
        this.canImport = cruvedImport.C > 0 && userCruved.C > 0;
      }
    });
  }

  get importRoute(): string {
    return `/import/${this.moduleCode}/process/upload`;
  }
}
