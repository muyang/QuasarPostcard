/**
 * WeChat Mini Program upload (upload as dev version) via miniprogram-ci.
 *
 * Usage:
 *   npm run upload                     # upload with default version
 *   npm run upload -- --ver 0.9.3      # upload with specific version
 */

const ci = require('miniprogram-ci');
const path = require('path');
const fs = require('fs');

const PROJECT_PATH = path.resolve(__dirname, '..', 'miniprogram');
const PRIVATE_KEY_PATH = path.join(PROJECT_PATH, 'private.key');
const APPID = 'wx2faa751fe04a0f04';

if (!fs.existsSync(PRIVATE_KEY_PATH)) {
  console.error('\n  Missing private key: miniprogram/private.key');
  console.error('  See "npm run preview" for setup instructions.\n');
  process.exit(1);
}

const project = new ci.Project({
  appid: APPID,
  type: 'miniProgram',
  projectPath: PROJECT_PATH,
  privateKeyPath: PRIVATE_KEY_PATH,
  ignores: ['node_modules/**/*'],
});

// Parse --ver
let version = '0.1.0';
const verIdx = process.argv.indexOf('--ver');
if (verIdx !== -1 && process.argv[verIdx + 1]) {
  version = process.argv[verIdx + 1];
}

ci.upload({
  project,
  version,
  desc: 'upload from CLI',
  setting: {
    es6: true,
    es7: true,
    minify: true,
    minifyJS: true,
    minifyWXML: true,
    minifyWXSS: true,
    autoPrefixWXSS: true,
  },
  onProgressUpdate(info) {
    if (info._status) console.log(info._status);
    if (info._msg) console.log(' ', info._msg);
  },
}).then(() => {
  console.log('\n Upload successful! Version: ' + version);
  console.log(' Go to https://mp.weixin.qq.com to submit for review.\n');
}).catch((err) => {
  console.error('\n Upload failed:', err.message || err);
  process.exit(1);
});
