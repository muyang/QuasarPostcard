/**
 * WeChat Mini Program preview via miniprogram-ci.
 *
 * Prerequisites:
 *   1. Go to https://mp.weixin.qq.com
 *   2. Development -> Dev Settings -> Upload Key -> Generate
 *   3. Save the private key as miniprogram/private.key
 *
 * Usage:
 *   npm run preview          # terminal QR code
 *   npm run preview -- --image    # save QR as preview-qrcode.png
 */

const ci = require('miniprogram-ci');
const path = require('path');
const fs = require('fs');

const PROJECT_PATH = path.resolve(__dirname, '..', 'miniprogram');
const PRIVATE_KEY_PATH = path.join(PROJECT_PATH, 'private.key');
const APPID = 'wx2faa751fe04a0f04';

// ---- check private key ----
if (!fs.existsSync(PRIVATE_KEY_PATH)) {
  console.error('\n  Missing private key: miniprogram/private.key\n');
  console.error('  How to get it:');
  console.error('    1. Open https://mp.weixin.qq.com');
  console.error('    2. Development -> Dev Settings -> Upload Key');
  console.error('    3. Generate a key and download it');
  console.error('    4. Save as miniprogram/private.key\n');
  process.exit(1);
}

const project = new ci.Project({
  appid: APPID,
  type: 'miniProgram',
  projectPath: PROJECT_PATH,
  privateKeyPath: PRIVATE_KEY_PATH,
  ignores: ['node_modules/**/*'],
});

const useImage = process.argv.includes('--image');

ci.preview({
  project,
  desc: 'preview from CLI',
  setting: {
    es6: true,
    es7: true,
    minify: true,
    minifyJS: true,
    minifyWXML: true,
    minifyWXSS: true,
    autoPrefixWXSS: true,
  },
  qrcodeFormat: useImage ? 'image' : 'terminal',
  qrcodeOutputDest: useImage ? path.resolve(__dirname, '..', 'preview-qrcode.png') : undefined,
  onProgressUpdate(info) {
    if (info._status) console.log(info._status);
    if (info._msg) console.log(' ', info._msg);
  },
}).then((result) => {
  console.log('\n Preview ready!');
  if (useImage) {
    console.log(' QR code image saved to: preview-qrcode.png');
  }
  console.log(' Scan the QR code with WeChat to preview.\n');
}).catch((err) => {
  console.error('\n Preview failed:', err.message || err);
  process.exit(1);
});
