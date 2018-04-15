const GetExportsForCode = require('./get_exports_for_code')
const fs = require('fs')
const util = require('util')
const _ = require('lodash')
const exec = util.promisify(require('child_process').exec)


function exportToJsString(exportsForFile) {
    exportsForFile.exportedNames
    exportsForFile.exportedDefaults
    return exportsForFile.exportedNames
}

async function readFileToString(fileName) {
    const readFile = util.promisify(fs.readFile)
    return readFile(fileName).then(contents => contents.toString())
}

async function getExportsForFileName(fileName) {
    try {
        const code = await readFileToString(fileName)
        const exportsForCode = new GetExportsForCode(code)
        exportsForCode.getExports()
        return exportsForCode
    } catch (err) {
        console.log(fileName, err)
    }
}

async function getJsFiles(dirName) {
    const { stdout, stderr } = await exec(`git -C ${dirName} ls-files  | grep '.jsx\\?$'`)
    if (stderr)
        console.log('stderr:', stderr)
    return _.filter(stdout.split('\n'), file => file.length > 0)
}

async function getAllExportsForDir(dirName, javascriptExport, useSemiColon) {
    const files = await getJsFiles(dirName)
    const getFiles = _.map(files, file => {
        return getExportsForFileName(`${dirName}${file}`)
    })

    const values = await Promise.all(getFiles)
    const filesAndExports = _.zip(files, values)
    const result = {}

    _.each(filesAndExports, fileAndExport => {
        const file = fileAndExport[0].replace(/\.[^/.]+$/, "")
        const getExportsForCode = fileAndExport[1]

        const exportedDefault = getExportsForCode.exportedDefault
        if (!(exportedDefault in result)) {
            result[exportedDefault] = []
        }

        let exportDefaultString = `import ${exportedDefault} from '${file}'`
        if (useSemiColon)
            exportDefaultString += ';'

        result[exportedDefault].push(exportDefaultString)

        _.each(getExportsForCode.exportedNames, exportedName => {
            if (!(exportedName in result)) {
                result[exportedName] = []
            }

            let exportNamedString = `import { ${exportedName} } from '${file}'`
            if (useSemiColon)
                exportNamedString += ';'

            result[exportedName].push(exportNamedString)
        })
    })

    if (javascriptExport in result)
        console.log(result[javascriptExport].join("\n"))
}

let dir = process.argv[2]
if (dir.slice(-1) !== '/')
    dir += '/'
const javascriptExport = process.argv[3]
const semis = process.argv[4]
const useSemiColon = process.argv.indexOf("--semi") !== -1

getAllExportsForDir(dir, javascriptExport, useSemiColon)
