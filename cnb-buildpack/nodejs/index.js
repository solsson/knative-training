console.log(`I feel important, or at least imported`);

// Contrary to https://github.com/projectriff/riff-buildpack#in-plain-english we don't get an npm install at build
var aguid;
try {
  aguid = require('aguid');
} catch (e) {
  aguid = x => `Got "${x}" but failed to load the aguid dependency`
}

module.exports = x => aguid(x);
