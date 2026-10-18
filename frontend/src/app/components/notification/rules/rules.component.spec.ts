import { ComponentFixture, TestBed } from '@angular/core/testing';
import { of } from 'rxjs';
import { RulesComponent } from './rules.component';
import { NotificationDataService } from '../notification-data.service';

describe('RulesComponent', () => {
  let component: RulesComponent;
  let fixture: ComponentFixture<RulesComponent>;
  let service: Record<string, jest.Mock>;

  beforeEach(() => {
    service = {
      getRules: jest.fn().mockReturnValue(of([{ code_category: 'A', code_method: 'EMAIL' }])),
      getRulesMethods: jest.fn().mockReturnValue(of([{ code: 'EMAIL' }])),
      getRulesCategories: jest.fn().mockReturnValue(of([{ code: 'A' }])),
      subscribe: jest.fn().mockReturnValue(of({})),
      unsubscribe: jest.fn().mockReturnValue(of({})),
    };
    TestBed.configureTestingModule({
      declarations: [RulesComponent],
      providers: [{ provide: NotificationDataService, useValue: service }],
    });
    // the template needs the material and translate modules, only the logic is tested here
    TestBed.overrideComponent(RulesComponent, { set: { template: '' } });
    fixture = TestBed.createComponent(RulesComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('loads the methods, the categories and the rules of the user', () => {
    expect(component.rulesMethods).toEqual([{ code: 'EMAIL' }]);
    expect(component.rulesCategories).toEqual([{ code: 'A' }]);
    expect(component.userRules).toEqual([{ code_category: 'A', code_method: 'EMAIL' }]);
  });

  it('subscribes and unsubscribes to a category with a method', () => {
    component.subscribe('A', 'EMAIL');
    component.unsubscribe('A', 'EMAIL');
    expect(service.subscribe).toHaveBeenCalledWith('A', 'EMAIL');
    expect(service.unsubscribe).toHaveBeenCalledWith('A', 'EMAIL');
  });
});
