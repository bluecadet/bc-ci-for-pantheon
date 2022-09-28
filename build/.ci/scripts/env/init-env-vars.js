#!/usr/bin/env node

var fs = require('fs');
const CONFIG = require('../../../.projectconfig.js');
// Save Config as settings.
fs.writeFileSync('.projectconfig.json', JSON.stringify(CONFIG, null, 2));
