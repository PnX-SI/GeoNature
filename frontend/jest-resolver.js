// Some libraries of the project are View Engine libraries (ex: ngx-translate 12, angular-tree-component),
// which cannot be used in TestBed as is. `ngcc` (run on install) processes them into an Ivy build, referenced
// by the `*_ivy_ngcc` fields of their package.json: prefer it when it exists.
module.exports = (path, options) =>
  options.defaultResolver(path, {
    ...options,
    packageFilter: (pkg) => {
      const ivy = pkg.fesm2015_ivy_ngcc || pkg.es2015_ivy_ngcc || pkg.main_ivy_ngcc;
      return ivy ? { ...pkg, main: ivy } : pkg;
    },
  });
