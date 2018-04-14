const babylon = require('babylon')
const _ = require('lodash')
const util = require('util')

// does not handle anonymous function, maybe should be camelCased filename?

const plugins = [
  'estree',
  'jsx',
  'flow',
  'flowComments',
  'typescript',
  'doExpressions',
  'objectRestSpread',
  'decorators',
  'decorators2',
  'classProperties',
  'classPrivateProperties',
  'classPrivateMethods',
  'exportDefaultFrom',
  'exportNamespaceFrom',
  'asyncGenerators',
  'functionBind',
  'functionSent',
  'dynamicImport',
  'numericSeparator',
  'optionalChaining',
  'importMeta',
  'bigInt',
  'optionalCatchBinding',
  'throwExpressions',
  'pipelineOperator',
  'nullishCoalescingOperator'
]

class GetExportsForFile {
    constructor(code) {
        this.code = code
    }

    async getExports() {
        this.body = this.parse(this.code)

        this.exportedNames = []
        this.exportedDefaults = []
        this.getDefaultExports()
        this.getNamedExports()
        return this.exportedNames
    }

    parse(code) {
        return babylon.parse(
            code,
            {sourceType: 'module', plugins: plugins}
        ).program.body
    }

    getDefaultExports() {
        const defaultExport = _.find(this.body, node => node.type === 'ExportDefaultDeclaration')
        if (!defaultExport)
            return

        if (defaultExport.declaration.type === 'Identifier') {
            this.exportedDefaults.push(defaultExport.declaration.name)
        }
        else if (defaultExport.declaration.type === 'CallExpression') {
            this.exportedDefaults.push(defaultExport.declaration.arguments[0].name)
        }
    }

    getNamedExports() {
        const namedExports = _.filter(this.body, node => node.type === 'ExportNamedDeclaration')
        _.each(namedExports, namedExport => {
            if (namedExport.declaration === null) {
                this.exportedNames.push(namedExport.specifiers[0].exported.name)
            }
            else if (namedExport.declaration.type === 'ClassDeclaration') {
                this.exportedNames.push(namedExport.declaration.id.name)
            }
            else if (namedExport.declaration.type === 'VariableDeclaration') {
                this.exportedNames.push(namedExport.declaration.declarations[0].id.name)
            }
        })

    }
}

module.exports = GetExportsForFile
