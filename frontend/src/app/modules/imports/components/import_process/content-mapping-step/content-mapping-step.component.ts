import { Component, OnInit, ViewChild, ViewEncapsulation } from '@angular/core';
import { Router, ActivatedRoute } from '@angular/router';
import { Validators } from '@angular/forms';
import { FormControl, FormGroup, FormBuilder } from '@angular/forms';

import { Observable, of } from 'rxjs';
import { forkJoin } from 'rxjs/observable/forkJoin';
import { concatMap, finalize } from 'rxjs/operators';

import { DataService } from '../../../services/data.service';
import { ContentMappingService } from '../../../services/mappings/content-mapping.service';
import { CommonService } from '@geonature_common/service/common.service';
import { SyntheseDataService } from '@geonature_common/form/synthese-form/synthese-data.service';
import { CruvedStoreService } from '@geonature_common/service/cruved-store.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { ContentMapping, ContentMappingValues } from '../../../models/mapping.model';
import { Step } from '../../../models/enums.model';
import { Import, ImportValues, Nomenclature } from '../../../models/import.model';
import { ImportProcessService } from '../import-process.service';

@Component({
  selector: 'content-mapping-step',
  styleUrls: ['content-mapping-step.component.scss'],
  templateUrl: 'content-mapping-step.component.html',
  encapsulation: ViewEncapsulation.None,
})
export class ContentMappingStepComponent implements OnInit {
  public step: Step;
  public selectMappingContentForm = new FormControl();
  public importData: Import;
  public userContentMappings: Array<ContentMapping>;
  public importValues: ImportValues;
  public showForm: boolean = false;
  public contentTargetForm: FormGroup;
  public spinner: boolean = false;
  public updateAvailable: boolean = false;
  public modalCreateMappingForm = new FormControl('');
  public createOrRenameMappingForm = new FormControl(null, [Validators.required]);
  public mappingSelected: boolean = false;
  public renameMappingFormVisible: boolean = false;
  public mappedFields: Set<string> = new Set<string>(); // TODO
  public unmappedFields: Set<string> = new Set<string>(); // TODO

  @ViewChild('modalConfirm') modalConfirm: any;
  @ViewChild('modalRedir') modalRedir: any;
  @ViewChild('deleteConfirmModal') deleteConfirmModal: any;

  constructor(
    //private stepService: StepsService,
    private _fb: FormBuilder,
    private _ds: DataService,
    private _synthese_ds: SyntheseDataService,
    public _cm: ContentMappingService,
    private _commonService: CommonService,
    private _router: Router,
    private _route: ActivatedRoute,
    private _modalService: NgbModal,
    public cruvedStore: CruvedStoreService,
    private importProcessService: ImportProcessService
  ) {}

  ngOnInit() {
    this.step = this._route.snapshot.data.step;
    this.importData = this.importProcessService.getImportData();
    this.contentTargetForm = this._fb.group({});

    forkJoin({
      contentMappings: this._ds.getContentMappings(),
      importValues: this._ds.getImportValues(this.importData.id_import),
    }).subscribe(({ contentMappings, importValues }) => {
      this.userContentMappings = contentMappings;

      this.selectMappingContentForm.valueChanges.subscribe((mapping) => {
        this.onSelectMapping(mapping);
      });

      this.importValues = importValues;
      this.contentTargetForm = this._fb.group({});
      for (let targetField of Object.keys(this.importValues)) {
        this.importValues[targetField].values.forEach((value, index) => {
          let control = new FormControl(null, [Validators.required]);
          let control_name = targetField + '-' + index;
          this.contentTargetForm.addControl(control_name, control);
          if (!this.importData.contentmapping) {
            // Search for a nomenclature with a label equals to the user value.
            let nomenclature = this.importValues[targetField].nomenclatures.find(
              (n) => n.label_default == value
            );
            if (nomenclature) {
              control.setValue(nomenclature);
              control.markAsDirty();
            }
          }
        });
      }
      if (this.importData.contentmapping) {
        this.fillContentFormWithMapping(this.importData.contentmapping);
      }
      this.showForm = true;
    });
  }

  // Used by select component to compare content mappings
  areMappingContentEqual(mc1: ContentMapping, mc2: ContentMapping): boolean {
    return (mc1 == null && mc2 == null) || (mc1 != null && mc2 != null && mc1.id === mc2.id);
  }

  areNomenclaturesEqual(n1: Nomenclature, n2: Nomenclature): boolean {
    return (
      (n1 == null && n2 == null) ||
      (n1 != null && n2 != null && n1.cd_nomenclature === n2.cd_nomenclature)
    );
  }

  onSelectMapping(mapping: ContentMapping) {
    this.contentTargetForm.reset();
    if (mapping) {
      this.fillContentFormWithMapping(mapping.values);
      this.mappingSelected = true;
    } else {
      this.mappingSelected = false;
    }
  }

  fillContentFormWithMapping(mappingvalues: ContentMappingValues) {
    for (let targetField of Object.keys(this.importValues)) {
      let type_mnemo = this.importValues[targetField].nomenclature_type.mnemonique;
      if (!(type_mnemo in mappingvalues)) continue;
      this.importValues[targetField].values.forEach((value, index) => {
        if (value in mappingvalues[type_mnemo]) {
          let control = this.contentTargetForm.get(targetField + '-' + index);
          let nomenclature = this.importValues[targetField].nomenclatures.find(
            (n) => n.cd_nomenclature === mappingvalues[type_mnemo][value]
          );
          if (nomenclature) {
            control.setValue(nomenclature);
          }
        }
      });
    }
  }
  showRenameMappingForm() {
    this.createOrRenameMappingForm.setValue(this.selectMappingContentForm.value.label);
    this.renameMappingFormVisible = true;
  }

  renameMapping(): void {
    this.spinner = true;
    this._ds
      .renameContentMapping(
        this.selectMappingContentForm.value.id,
        this.createOrRenameMappingForm.value
      )
      .pipe(
        finalize(() => {
          this.spinner = false;
          this.spinner = false;
          this.renameMappingFormVisible = false;
        })
      )
      .subscribe((mapping: ContentMapping) => {
        let index = this.userContentMappings.findIndex((m: ContentMapping) => m.id == mapping.id);
        this.selectMappingContentForm.setValue(mapping);
        this.userContentMappings[index] = mapping;
      });
  }

  onSelectNomenclature(targetFieldValue: string) {
    let formControl = this.contentTargetForm.controls[targetFieldValue];
  }

  onPreviousStep() {
    this.importProcessService.navigateToPreviousStep(this.step);
  }

  isNextStepAvailable(): boolean {
    return this.contentTargetForm.valid;
  }
  deleteMappingEnabled() {
    // a mapping have been selected and we have delete right on it
    return (
      this.selectMappingContentForm.value != null && this.selectMappingContentForm.value.cruved.D
    );
  }
  createMapping() {
    this.spinner = true;
    this._ds
      .createContentMapping(this.modalCreateMappingForm.value, this.computeContentMappingValues())
      .pipe()
      .subscribe(
        () => {
          this.processNextStep();
        },
        () => {
          this.spinner = false;
        }
      );
  }

  updateMapping() {
    this.spinner = true;
    let name = '';
    if (this.modalCreateMappingForm.value != this.selectMappingContentForm.value.label) {
      name = this.modalCreateMappingForm.value;
    }
    this._ds
      .updateContentMapping(
        this.selectMappingContentForm.value.id,
        this.computeContentMappingValues(),
        name
      )
      .pipe()
      .subscribe(
        () => {
          this.processNextStep();
        },
        () => {
          this.spinner = false;
        }
      );
  }
  openDeleteModal() {
    this._modalService.open(this.deleteConfirmModal);
  }
  deleteMapping() {
    this.spinner = true;
    let mapping_id = this.selectMappingContentForm.value.id;
    this._ds
      .deleteContentMapping(mapping_id)
      .pipe()
      .subscribe(
        () => {
          this._commonService.regularToaster(
            'success',
            'Le mapping ' + this.selectMappingContentForm.value.label + ' a bien été supprimé'
          );
          this.selectMappingContentForm.setValue(null, { emitEvent: false });
          this.userContentMappings = this.userContentMappings.filter((mapping) => {
            return mapping.id !== mapping_id;
          });
          this.spinner = false;
        },
        () => {
          this.spinner = false;
        }
      );
  }
  onNextStep() {
    if (!this.isNextStepAvailable()) {
      return;
    }
    let contentMapping = this.selectMappingContentForm.value;
    if (
      this.contentTargetForm.dirty &&
      (this.cruvedStore.cruved.IMPORT.module_objects.MAPPING.cruved.C > 0 ||
        (contentMapping && contentMapping.cruved.U && !contentMapping.public))
    ) {
      if (contentMapping && !contentMapping.public) {
        this.modalCreateMappingForm.setValue(contentMapping.label);
        this.updateAvailable = true;
      } else {
        this.modalCreateMappingForm.setValue('');
        this.updateAvailable = false;
      }
      this._modalService.open(this.modalConfirm, { size: 'lg' });
    } else {
      this.spinner = true;
      this.processNextStep();
    }
  }
  onSaveData(): Observable<Import> {
    return of(this.importData).pipe(
      concatMap((importData: Import) => {
        if (
          this.contentTargetForm.dirty ||
          this.mappingSelected ||
          Object.keys(this.importValues).length === 0
        ) {
          let values: ContentMappingValues = this.computeContentMappingValues();
          return this._ds.setImportContentMapping(importData.id_import, values);
        } else {
          return of(importData);
        }
      })
    );
  }
  processNextStep() {
    this.onSaveData().subscribe((importData: Import) => {
      this.importProcessService.setImportData(importData);
      this.importProcessService.navigateToNextStep(this.step);
    });
  }

  computeContentMappingValues(): ContentMappingValues {
    let values = {} as ContentMappingValues;
    for (let targetField of Object.keys(this.importValues)) {
      let _values = {};
      this.importValues[targetField].values.forEach((value, index) => {
        let control = this.contentTargetForm.controls[targetField + '-' + index];
        _values[value] = control.value.cd_nomenclature;
      });
      values[this.importValues[targetField].nomenclature_type.mnemonique] = _values;
    }
    return values;
  }
}
