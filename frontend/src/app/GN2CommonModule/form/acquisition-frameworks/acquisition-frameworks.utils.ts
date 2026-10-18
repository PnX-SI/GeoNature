/** Sort acquisition frameworks by name, using the locale collation */
export function sortAcquisitionFrameworks(items: Array<any>): Array<any> {
  const collator = new Intl.Collator();
  return items.sort((a, b) =>
    collator.compare(a.acquisition_framework_name, b.acquisition_framework_name)
  );
}
