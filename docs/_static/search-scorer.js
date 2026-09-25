/*
 * Scorer de la recherche Sphinx (option `html_search_scorer` de conf.py).
 * Reprend les valeurs par défaut de Sphinx et relègue les pages de la
 * référence API (générées par autoapi) après celles de la documentation.
 */
var Scorer = {
  // Pénalité appliquée aux résultats de la référence API : assez grande pour
  // qu'ils passent toujours après les autres, sans changer leur ordre relatif.
  apiPenalty: 1000,

  score: (result) => {
    const [docname, title, anchor, descr, score, filename, kind] = result;
    if (docname === "api-references" || docname.startsWith("autoapi/")) {
      return score - Scorer.apiPenalty;
    }
    return score;
  },

  // Valeurs par défaut de Sphinx (sphinx/themes/basic/static/searchtools.js)
  // query matches the full name of an object
  objNameMatch: 11,
  // or matches in the last dotted part of the object name
  objPartialMatch: 6,
  // Additive scores depending on the priority of the object
  objPrio: {
    0: 15, // used to be importantResults
    1: 5, // used to be objectResults
    2: -5, // used to be unimportantResults
  },
  //  Used when the priority is not in the mapping.
  objPrioDefault: 0,

  // query found in title
  title: 15,
  partialTitle: 7,
  // query found in terms
  term: 5,
  partialTerm: 2,
};
