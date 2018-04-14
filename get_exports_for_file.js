const babylon = require('babylon')
const fs = require('fs')
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
    constructor(fileName) {
        this.fileName = fileName
    }

    async getExports() {
        const fileContents = await this.readFile()
        this.body = this.parse(fileContents.toString())

        this.exportedNames = []
        this.getDefaultExports()
        this.getNamedExports()
        return _.uniq(this.exportedNames)
    }

    parse(code) {
        return babylon.parse(
            code,
            {sourceType: 'module', plugins: plugins}
        ).program.body
    }

    async readFile() {
        const readFile = util.promisify(fs.readFile)
        return readFile(this.fileName)
    }

    getDefaultExports() {
        const defaultExport = _.find(this.body, node => node.type === 'ExportDefaultDeclaration')
        if (!defaultExport)
            return

        if (defaultExport.declaration.type === 'Identifier') {
            this.exportedNames.push(defaultExport.declaration.name)
        }
        else if (defaultExport.declaration.type === 'CallExpression') {
            this.exportedNames.push(defaultExport.declaration.arguments[0].name)
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
