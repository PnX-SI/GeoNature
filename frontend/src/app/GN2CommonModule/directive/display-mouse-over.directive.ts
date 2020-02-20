import {Directive, ElementRef, Input, Renderer2 } from '@angular/core';

@Directive({
  selector: '[displayMouseOver]',
  host: {
    '(mouseenter)': 'onMouseEnter()',
    '(mouseleave)': 'onMouseLeave()'
  }
})
export class DisplayMouseOverDirective {
	private _defaultColor = null;
  private _defaultSelector = '.btn';
  private el: HTMLElement;

  constructor(el: ElementRef, private renderer: Renderer2) { 
  	this.el = el.nativeElement; 
  }

  @Input('highlightColor') _highlightColor: string;
  @Input('selector') _selector: string;

  get highlightColor() {
    return this._highlightColor || this._defaultColor;
  }

  get selector() {
    return this._selector || this._defaultSelector;
  }

  onMouseEnter() { 
    this._defaultColor = this.el.style.backgroundColor;
  	let els = this.el.querySelectorAll(this.selector);

    for (var i=0; i < els.length; i++) {
    		els[i].classList.remove('d-none');
    }
    this.el.style.backgroundColor = this.highlightColor;
  }
  onMouseLeave() { 
  	let els = this.el.querySelectorAll(this.selector);
    for (var i=0; i < els.length; i++) {
        els[i].classList.add('d-none');
    }
    this.el.style.backgroundColor = this._defaultColor;
  }
}