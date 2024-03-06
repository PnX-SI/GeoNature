// import { ComponentFixture, TestBed } from '@angular/core/testing';

// import { AcquisitionFrameworksComponent } from './acquisition-frameworks.component';
// import { DataFormService } from '../data-form.service';

import { Component, OnInit } from '@angular/core';
import { ConfigService } from '../../../services/config.service';
import { MountConfig } from 'cypress/angular';
import { HttpClient } from '@angular/common/http';
import { GN2CommonModule } from '../../GN2Common.module';

@Component({
  selector: 'pnx-pouet',
  template: '<h1>POUET POUET</h1>',
})
export class testComponent implements OnInit {
  constructor(configService: ConfigService) {}

  ngOnInit() {}
}


describe('testComponent', () => {
  const config: MountConfig<testComponent> = {
    imports: [GN2CommonModule],
    providers: [ConfigService, HttpClient]
  } 



  it('uses custom text for the button label', () => {
    // cy.stub(window, 'prompt').returns('my custom message')
    // const cs: ConfigService = new ConfigService();

    // // After that, mount your component

    // cy.window().its('prompt').should('be.called')
    // cy.get('.name').should('have.value', 'my custom message')
    // console.log(cy.stub(_ds, "getAcquisitionFrameworks").returns({}))

    
    cy.mount(testComponent, config)
  });
});

