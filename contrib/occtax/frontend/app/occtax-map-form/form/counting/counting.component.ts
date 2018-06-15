import {
  Component,
  OnInit,
  Input,
  Output,
  EventEmitter,
  ViewEncapsulation,
  ViewChild
} from "@angular/core";
import {
  FormControl,
  FormBuilder,
  FormGroup,
  FormArray,
  Validators
} from "@angular/forms";
import { OcctaxFormService } from "../occtax-form.service";
import { CommonService } from "@geonature_common/service/common.service";
import { ModuleConfig } from "../../../module.config";

@Component({
  selector: "pnx-counting",
  templateUrl: "./counting.component.html",
  styleUrls: ["./counting.component.scss"],
  encapsulation: ViewEncapsulation.None
})
export class CountingComponent implements OnInit {
  public occtaxConfig = ModuleConfig;
  @Input() index: number;
  @Input() length: number;
  @Input() formArray: FormArray;
  @Output() countingRemoved = new EventEmitter<any>();
  @Output() countingAdded = new EventEmitter<any>();
  @ViewChild("typeDenombrement") public typeDenombrement: any;
  constructor(
    public fs: OcctaxFormService,
    private _commonService: CommonService
  ) {}

  ngOnInit() {
    // autocomplete count_max
    (this.formArray.controls[
      this.fs.indexCounting
    ] as FormGroup).controls.count_min.valueChanges
      //.debounceTime(500)
      .distinctUntilChanged()
      .subscribe(value => {
        if (
          this.formArray.controls[this.fs.indexCounting].value.count_max ===
            null ||
          (this.formArray.controls[this.fs.indexCounting] as FormGroup).controls
            .count_max.pristine
        ) {
          (this.formArray.controls[
            this.fs.indexCounting
          ] as FormGroup).patchValue({
            count_max: value
          });
        }
      });
  }

  onAddCounting() {
    this.countingAdded.emit();
  }

  onRemoveCounting() {
    this.countingRemoved.emit(this.index);
  }
}
