var BASE_URL = 'https://card.qpvisiontech.com';
//var BASE_URL = 'http://localhost:8100';
var TOKEN = '';

function setToken(token) {
  TOKEN = token || '';
}

function setBaseUrl(url) {
  BASE_URL = url || BASE_URL;
}

function request(method, path, data, options) {
  options = options || {};
  return new Promise((resolve, reject) => {
    wx.request({
      url: BASE_URL + path,
      method: method,
      data: data,
      header: {
        'Content-Type': 'application/json',
        ...(TOKEN ? { 'Authorization': 'Bearer ' + TOKEN } : {}),
      },
      success(res) {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(res.data);
        } else if (res.statusCode === 401 && !options._retry) {
          // Token expired, try re-login
          wx.removeStorageSync('token');
          TOKEN = '';
          wx.login({
            success(loginRes) {
              if (loginRes.code) {
                miniLogin(loginRes.code).then(() => {
                  request(method, path, data, { _retry: true }).then(resolve).catch(reject);
                }).catch(reject);
              } else {
                reject({ statusCode: 401, data: { detail: 'Not authenticated' } });
              }
            },
            fail: reject,
          });
        } else {
          reject({ statusCode: res.statusCode, data: res.data });
        }
      },
      fail(err) { reject(err); },
    });
  });
}

// Auth
function miniLogin(code) {
  return request('POST', '/api/auth/wechat/miniprogram/login', { code: code });
}

function getMe() {
  return request('GET', '/api/auth/me');
}

// Postcards
function getPostcards(skip, limit) {
  return request('GET', '/api/postcards', { skip: skip || 0, limit: limit || 50 });
}

function createPostcard(body) {
  return request('POST', '/api/postcards', body);
}

function updatePostcard(id, body) {
  return request('PUT', '/api/postcards/' + id, body);
}

function deletePostcard(id) {
  return request('DELETE', '/api/postcards/' + id);
}

function batchDeletePostcards(ids) {
  return request('POST', '/api/postcards/batch-delete', { ids: ids });
}

// Materials
function getTemplates() {
  var templates = getApp().globalData.templates;
  if (templates && templates.length > 0) return Promise.resolve(templates);
  return request('GET', '/api/materials/templates', { status: 'published_free,published_member', limit: 1000 })
    .then(function(res) { return res.items || res; });
}

function getStamps() {
  var stamps = getApp().globalData.stamps;
  if (stamps && stamps.length > 0) return Promise.resolve(stamps);
  return request('GET', '/api/materials/stamps', { status: 'published_free,published_member', limit: 1000 })
    .then(function(res) { return res.items || res; });
}

function getPostmarks() {
  var postmarks = getApp().globalData.postmarks;
  if (postmarks && postmarks.length > 0) return Promise.resolve(postmarks);
  return request('GET', '/api/materials/postmarks', { status: 'published_free,published_member', limit: 1000 })
    .then(function(res) { return res.items || res; });
}

function getConfig() {
  return request('GET', '/api/materials/config', {}).catch(function() { return {}; });
}

function getStampGroups() {
  return request('GET', '/api/materials/stamp-groups', {});
}

function getPostmarkGroups() {
  return request('GET', '/api/materials/postmark-groups', {});
}

// Image URL helper
function imageUrl(path, size) {
  if (!path) return '';
  if (path.indexOf('http') === 0) return path;
  var url = BASE_URL + '/api/images/' + path.replace('/static/', '');
  if (size === 'thumb' || size === 'small') {
    url += (url.indexOf('?') >= 0 ? '&' : '?') + 'size=' + size;
  }
  return url;
}


// Resolve display_url for items with image_url
function resolveUrls(items) {
  if (!items || !items.length) return items;
  return items.map(function(item) {
    if (item.image_url) {
      item.display_url = item.image_url.indexOf('http') === 0
        ? item.image_url
        : imageUrl(item.image_url, 'thumb');
    }
    return item;
  });
}
module.exports = {
  setToken: setToken,
  setBaseUrl: setBaseUrl,
  miniLogin: miniLogin,
  getMe: getMe,
  getPostcards: getPostcards,
  createPostcard: createPostcard,
  updatePostcard: updatePostcard,
  deletePostcard: deletePostcard,
  batchDeletePostcards: batchDeletePostcards,
  getTemplates: getTemplates,
  getStamps: getStamps,
  getPostmarks: getPostmarks,
  getConfig: getConfig,
  getStampGroups: getStampGroups,
  getPostmarkGroups: getPostmarkGroups,
  imageUrl: imageUrl,
  resolveUrls: resolveUrls,
};
