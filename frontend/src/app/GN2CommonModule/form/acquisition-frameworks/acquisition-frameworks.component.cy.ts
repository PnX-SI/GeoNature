// import { ComponentFixture, TestBed } from '@angular/core/testing';

// import { AcquisitionFrameworksComponent } from './acquisition-frameworks.component';
// import { DataFormService } from '../data-form.service';

import { Component, OnInit } from '@angular/core';
import { ConfigService } from '../../../services/config.service';

@Component({
  selector: 'pnx-pouet',
  template: '<h1>POUET POUET</h1>',
})
export class testComponent implements OnInit {
  constructor(configService: ConfigService) { }

  ngOnInit() { }
}

export abstract class ConfigMock { }

describe('testComponent', () => {

  it('uses custom text for the button label', () => {

    cy.mount(testComponent, {
      imports: [],
      declarations: [testComponent],
      providers: [{ provide: ConfigService, useClass: ConfigMock }],
    });
  });
});
