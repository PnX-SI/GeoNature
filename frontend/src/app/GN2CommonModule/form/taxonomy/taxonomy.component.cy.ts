// import { async, ComponentFixture, TestBed } from '@angular/core/testing';
// import { HttpClient, HttpHandler } from '@angular/common/http';
// import { ToastrService, ToastrConfig } from 'ngx-toastr';

// import { TaxonomyComponent } from './taxonomy.component';
// import { DataFormService } from '../data-form.service';
// import { CommonService } from '@geonature_common/service/common.service';
// import {FormsModule, ReactiveFormsModule} from '@angular/forms';
// import { NgbModule } from '@ng-bootstrap/ng-bootstrap';
// import { TranslateModule, TranslateLoader, TranslateService,  } from '@ngx-translate/core';
// import { DisableControlDirective } from '../disable-control.directive';
// import { $ } from 'protractor';
// import { TranslateStore,  } from '@ngx-translate/core/src/translate.store';
// import { NgbTypeaheadConfig } from '@ng-bootstrap/ng-bootstrap/typeahead/typeahead-config';

// class FakeToasterService {
//   constructor() {}
// }

// class FakeTranslateService {
//   constructor(){}
// }

// class FakeTranslateStore {
//   constructor() {}
// }

// class FakeNgbTypeahead{
//   constructor(){}
// }

import { TaxonomyComponent } from './taxonomy.component';

describe('TaxonomyComponent', () => {

  it('show component', () => {
    
    cy.mount(TaxonomyComponent, {
      componentProperties: {},
      imports: [],
      declarations: [],
      providers: [],
    });
  });
});


// describe('TaxonomyComponent', () => {
//   let component: TaxonomyComponent;
//   let fixture: ComponentFixture<TaxonomyComponent>;
//   let toasterConfig = {
//     positionClass: 'toast-top-center',
//     tapToDismiss: true,
//     timeOut: 2000
// };

//   beforeEach(async(() => {
//     TestBed.configureTestingModule({
//       declarations: [ TaxonomyComponent, DisableControlDirective ],
//       imports: [ReactiveFormsModule, FormsModule, NgbModule, TranslateModule],
//       providers : [{provide: TranslateService, useClass: FakeTranslateService},
//          DataFormService, CommonService, HttpClient, HttpHandler,
//          {'provide': ToastrService, 'useClass': FakeToasterService},
//          {'provide': TranslateStore, 'useClass': FakeTranslateStore},
//          {'provide': NgbTypeaheadConfig, 'useClass': FakeNgbTypeahead},
//          FakeNgbTypeahead
//          ]
//     })
//     .compileComponents();
//   }));

//   beforeEach(() => {
//     fixture = TestBed.createComponent(TaxonomyComponent);
//     component = fixture.componentInstance;
//     fixture.detectChanges();
//   });

//   it('should be created', () => {
//     expect(component).toBeTruthy();
//   });

//   it('lala', () => {
//     expect(true).toBeTruthy();
//   });

//   // it('formcontrol should be fullfil after select a taxon', () => {

//   // });
// });
