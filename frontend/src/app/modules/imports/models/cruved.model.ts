export interface Cruved {
  C: boolean;
  R: boolean;
  U: boolean;
  V: boolean;
  E: boolean;
  D: boolean;
}

export interface CruvedWithScope {
  C: number;
  R: number;
  U: number;
  V: number;
  E: number;
  D: number;
}

export function toBooleanCruved(
  cruved: CruvedWithScope,
  compare_function: Function = (c) => c > 0
): Cruved {
  return Object.assign(
    {},
    ...Object.entries(cruved as CruvedWithScope).map(([key, value]) => ({
      [key]: value > 0,
    }))
  );
}
