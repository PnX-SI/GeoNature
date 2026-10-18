import { MappingThemeComponent } from './mapping-theme.component';

describe('MappingThemeComponent', () => {
  it('sorts the source fields, ignoring case', () => {
    const component = new MappingThemeComponent({} as any);
    component.sourceFields = ['b', 'C', 'a'];
    component.ngOnInit();
    expect(component.sourceFields).toEqual(['a', 'b', 'C']);
  });
});
