var cache = {};

function loadImage(remoteUrl) {
  if (!remoteUrl) return Promise.resolve('');
  if (cache[remoteUrl]) return Promise.resolve(cache[remoteUrl]);

  return new Promise((resolve, reject) => {
    wx.downloadFile({
      url: remoteUrl,
      success(res) {
        if (res.statusCode === 200) {
          cache[remoteUrl] = res.tempFilePath;
          resolve(res.tempFilePath);
        } else {
          reject(new Error('Download failed: ' + res.statusCode));
        }
      },
      fail: reject,
    });
  });
}

function clearCache() {
  cache = {};
}

module.exports = {
  loadImage: loadImage,
  clearCache: clearCache,
};
