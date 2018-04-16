# add-js-import

This package is used to write the javascript es6 import for you.  Put the point over the javascript name that you want to get the import statement for.  Then call add-js-import-at-point.  This will add the import to the top of the file for you.

This currently requires you to use projectile, its required for the function (projectile-project-root) which is a little lazy but if people use the package I'll put the work in to remove the dependency.
Also this requires a node package babylon to get the javascript AST.  The package will automatically run npm install for you if the package isn't found.  This is maybe controversial but is a good experience for the package user.

## Todo
This is in an alpha state.
The following needs to be done:
- [ ] Handle errors (file you are in doesnt compile)
- [ ] put import at bottom of import list
- [ ] handle more than one matches
- [ ] make install plan
- [ ] check if file is already being imported from
- [ ] requires projectile
