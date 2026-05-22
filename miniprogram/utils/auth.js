const api = require('./api');

function wxMiniLogin() {
  return new Promise((resolve, reject) => {
    wx.login({
      success(res) {
        if (res.code) {
          api.miniLogin(res.code).then(data => {
            if (data.success && data.token) {
              wx.setStorageSync('token', data.token);
              api.setToken(data.token);
              resolve(data);
            } else {
              reject(new Error(data.message || '登录失败'));
            }
          }).catch(reject);
        } else {
          reject(new Error('wx.login 失败'));
        }
      },
      fail: reject,
    });
  });
}

function checkLogin() {
  const token = wx.getStorageSync('token');
  if (!token) return false;
  api.setToken(token);
  return true;
}

function logout() {
  wx.removeStorageSync('token');
  api.setToken('');
}

module.exports = {
  wxMiniLogin,
  checkLogin,
  logout,
};
