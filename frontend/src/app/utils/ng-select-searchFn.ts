export function customSearchFn(term: string, item: any, search_field: string) {
  const terms = _removeAccent(term).split(' ');
  return (
    terms
      .map((el) => _removeAccent(item[search_field]).includes(el)) //return true or false
      .filter((res) => res === false).length === 0 //filter les elements qui ne sont pas matché
  ); //s'il yen a l'item ne doit pas être affiché
}

//Fonction permettant une mise en minuscule + suppression des accents
function _removeAccent(term) {
  return term
    .toLowerCase()
    .trim()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '');
}
