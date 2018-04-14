const GetExportsForFile = require('./get_exports_for_file')

const util = require('util')
const _ = require('lodash')
const exec = util.promisify(require('child_process').exec)


async function getExportsForFileName(fileName) {
    try {
        const exportsForFile = new GetExportsForFile(fileName)
        return await exportsForFile.getExports()
    } catch (err) {
        console.log(fileName, err)
    }
}

async function getJsFiles(dirName) {
    const { stdout, stderr } = await exec(`git -C ${dirName} ls-files  | grep '.js$'`)
    if (stderr)
        console.log('stderr:', stderr)
    return _.filter(stdout.split('\n'), file => file.length > 0)
}

// need to differentiate between named and default exports

async function getAllExportsForDir(dirName, javascriptExport) {
    const files = await getJsFiles(dirName)
    const getFiles = _.map(files, file => {
        return getExportsForFileName(`${dirName}${file}`)
    })
    const values = await Promise.all(getFiles)

    const results = {}
    const filesAndExports = _.zip(files, values)
    _.each(filesAndExports, filesAndExport => {
        _.each(filesAndExport[1], exportName => {
            if (!(exportName in results)) {
                results[exportName] = []
            }

            results[exportName].push(filesAndExport[0])
        })
    })
    console.log(JSON.stringify(results[javascriptExport]))
}

getAllExportsForDir(process.argv[2], process.argv[3])
