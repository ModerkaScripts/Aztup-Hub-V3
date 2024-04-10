import express from 'express';
import path from 'path';
import fs from 'fs';
import {randomBytes, createHash} from 'crypto';
import gameList from './gameList.json';
import {config} from 'dotenv';

config();

const router = express();
router.use(express.json());

const API_KEY = process.env.API_KEY;

const requireRegex = /require\(['"]([^'"]+)['"]\)/g;
const sharedRequireRegex = /sharedRequire\(['"]([^'"]+)['"]\)/g;
const getServerConstantRegex = /getServerConstant\(['"]([^'"]+)['"]\)/g;

function getAllRequireForFile(
    filePath: string,
    gameId: string,
    gameName: string,
    original: boolean = true,
    fileIds: Map<string, string> = new Map(),
    allFiles: Map<string, string> = new Map(),
    serverConstants: Map<string, string> = new Map()
) : [string, Map<string, string>] {
    const extension = path.parse(filePath).ext;
    const gameNameSpaceLess = gameName.replace(/\s/g, '');

    const baseAppend = fs.readFileSync('base-append.lua');
    const isFolder = fs.existsSync(path.join(__dirname, 'files', 'games', gameName!.replace(/\s/g, '')));

    let fileContent = fs.readFileSync(filePath).toString();

    // We turn JSON into a lua string that we can then parse later
    if (extension === '.json') {
        fileContent = `return [[${JSON.stringify(JSON.parse(fileContent))}]]`;
    };

    fileContent = fileContent.replace('GAMES_SETUP();', `if (gameName == '${gameName}') then require('games/${gameNameSpaceLess}${isFolder ? '/main.lua' : '.lua'}') end`)
    fileContent = fileContent.replace(requireRegex, (str, scriptPath) => {
        const realPath = path.join(path.join(filePath, '../'), scriptPath);
        let [fileContent] = getAllRequireForFile(realPath, gameId, gameName, false, fileIds, allFiles, serverConstants)
        fileContent = fileContent.split('\n').map(str => '\t' + str).join('\n');

        return `(function()\n${fileContent}\nend)()`;
    });

    fileContent = fileContent.replace(sharedRequireRegex, (str, scriptPath) => {
        let oldFilePath = filePath;
        if (scriptPath.startsWith('@')) {
            oldFilePath = 'files/_.lua';
            scriptPath = scriptPath.substring(1);
        }

        const realPath = path.join(path.join(oldFilePath, '../'), scriptPath);
        const [fileContent] = getAllRequireForFile(realPath, gameId, gameName, false, fileIds, allFiles, serverConstants);

        if (!fileIds.has(realPath)) {
            allFiles.set(realPath, fileContent);
            fileIds.set(realPath, createHash('sha256').update(realPath).digest('hex'));
        }

        return `sharedRequires['${fileIds.get(realPath)}']` // (function()\n${fileContent}\nend)()`;
    });
    fileContent = fileContent.replace(getServerConstantRegex, (str, constName) => {
        if (!serverConstants.has(constName)) {
            const hash = createHash('md5').update(gameNameSpaceLess + constName).digest('hex');
            serverConstants.set(constName, hash);
        }
        return `serverConstants['${serverConstants.get(constName)}']`
    });

    if (original) {
        // If its the original file(source.lua) we append all the sharedRequires['test'] = (function() end)(); and we also append the base-append.lua file

        let sharedRequires = '';

        allFiles.forEach((fileContent, fileId) => {
            fileContent = fileContent.split('\n').map((str) => {
                return '\t' + str;
            }).join('\n');
            sharedRequires += `\nsharedRequires['${fileIds.get(fileId)}'] = (function()\n${fileContent}\nend)();\n`;
        });

        fileContent = baseAppend + sharedRequires + fileContent;
    };

    return [fileContent, serverConstants];
};

router.get('/compile', (req, res) => {
    const version = randomBytes(8).toString('hex');
    const metadata: any = {games: {}, version};
    const serverConstants: any = [];

    if (!fs.existsSync('bundled')) fs.mkdirSync('bundled');
    if (!fs.existsSync(`bundled/${version}`)) fs.mkdirSync(`bundled/${version}`);
    if (!fs.existsSync(`bundled/latest`)) fs.mkdirSync(`bundled/latest`);

    for (const [gameId, gameName] of Object.entries(gameList)) {
        try {
            let [outFile, smallServerConstants] = getAllRequireForFile(path.join('files', 'source.lua'), gameId, gameName);
            const constants: any = {};
            smallServerConstants.forEach((i, v) => constants[i] = v);

            serverConstants.push({gameId, constants});

            fs.writeFileSync(`bundled/latest/${gameName.replace(/\s/g, '')}.lua`, outFile);
            fs.writeFileSync(`bundled/${version}/${gameName.replace(/\s/g, '')}.lua`, outFile);
        } catch (error: any) {
            console.log(error);

            return res.json({
                success: false,
                message: error.message
            })
        }
    }

    // Remove all spaces from game metadata
    Object.entries(gameList).forEach(([i, v]) => metadata.games[i] = v.replace(/\s/g, ''));
    fs.writeFileSync(`bundled/${version}/metadata.json`, JSON.stringify(metadata));
    fs.writeFileSync(`bundled/latest/metadata.json`, JSON.stringify(metadata));
    fs.writeFileSync(`bundled/latest/serverConstants.json`, JSON.stringify(serverConstants));

    return res.json({success: true});
});

router.get('/gameList', (req, res) => {
    return res.json(gameList);
});

router.use((req, res, next) => {
    const apiKey = req.header('Authorization');
    if (apiKey !== API_KEY) return res.sendStatus(401);

    next();
})

router.post('/getFile', (req, res) => {
    const paths = req.body.paths as string[];

    if (paths[0].startsWith('@')) {
        paths[0] = paths[0].substring(1);
        paths[1] = '';
    } else {
        paths[1] = path.join(paths[1], '../');
    }

    let filePath = path.join('files', paths[1], paths[0]);
    const fileExists = fs.existsSync(filePath);

    if (!fileExists) {
        const pathInfo = path.parse(filePath);
        filePath = path.join(pathInfo.dir, pathInfo.name, '/main.lua');
    }

    res.header('File-Path', filePath.substring(6));
    return res.send(fs.readFileSync(filePath).toString());
});

router.use(express.static(path.join(__dirname, 'files')));

router.use((req, res, next) => {
    return res.status(400).json({
        success: false,
        code: 404,
        message: 'Page not found.'
    })
})

router.listen(4566, () => {
    console.log('app listening on port 4566');
})