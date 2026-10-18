import {
  ComponentRef,
  Directive,
  DoCheck,
  Input,
  OnDestroy,
  Renderer2,
  ViewContainerRef,
} from '@angular/core';
import { UntypedFormGroup } from '@angular/forms';
import { ConfigService } from '@geonature/services/config.service';
import { FormDef, WidgetContext, WidgetEntry } from './widget-registry';

/**
 * Render the component of a widget registry entry (see ``WIDGET_REGISTRY``) and keep its inputs
 * up to date with the field definition, as template bindings would do.
 * (``ngComponentOutlet`` cannot set inputs before Angular 16.)
 *
 * @example
 * <ng-container
 *   [pnxFormWidget]="entry"
 *   [widgetDef]="formDefComp"
 *   [widgetRawDef]="formDef"
 *   [widgetForm]="form"
 * ></ng-container>
 */
@Directive({
  selector: '[pnxFormWidget]',
})
export class FormWidgetDirective implements DoCheck, OnDestroy {
  @Input('pnxFormWidget') entry: WidgetEntry;
  /** Definition of the field, attributes evaluated against the current form value */
  @Input() widgetDef: FormDef;
  /** Definition of the field as given to the dynamic form */
  @Input() widgetRawDef: FormDef;
  @Input() widgetForm: UntypedFormGroup;

  private _ref?: ComponentRef<any>;
  private _currentEntry?: WidgetEntry;
  private _applied = new Map<string, any>();
  private _dataQa?: string;

  constructor(
    private _viewContainer: ViewContainerRef,
    private _renderer: Renderer2,
    private _config: ConfigService
  ) {}

  ngDoCheck() {
    if (this.entry !== this._currentEntry) {
      this._create();
    }
    if (!this._ref) {
      return;
    }
    const ctx: WidgetContext = {
      def: this.widgetDef,
      rawDef: this.widgetRawDef,
      form: this.widgetForm,
      control: this.widgetForm?.get(this.widgetDef.attribut_name) ?? null,
      config: this._config,
    };
    this._setInputs(this.entry.inputs(ctx));
    this._setDataQa(this.entry.dataQa?.(ctx));
  }

  ngOnDestroy() {
    this._ref?.destroy();
  }

  private _create() {
    this._ref?.destroy();
    this._ref = undefined;
    this._applied.clear();
    this._dataQa = undefined;
    this._currentEntry = this.entry;
    if (!this.entry) {
      return;
    }
    this._ref = this._viewContainer.createComponent(this.entry.component);
    const host = this._ref.location.nativeElement;
    for (const [style, value] of Object.entries(this.entry.hostStyle ?? {})) {
      this._renderer.setStyle(host, style, value);
    }
  }

  /** Set only the inputs that changed (all of them the first time, even if ``undefined``) */
  private _setInputs(inputs: Record<string, any>) {
    for (const [name, value] of Object.entries(inputs)) {
      if (!this._applied.has(name) || !Object.is(this._applied.get(name), value)) {
        this._applied.set(name, value);
        this._ref.setInput(name, value);
      }
    }
  }

  private _setDataQa(dataQa?: string) {
    if (dataQa !== undefined && dataQa !== this._dataQa) {
      this._dataQa = dataQa;
      this._renderer.setAttribute(this._ref.location.nativeElement, 'data-qa', dataQa);
    }
  }
}
