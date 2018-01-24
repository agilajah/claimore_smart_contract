"use strict";
global.__base = __dirname + "/"; // Need for node modules paths

const Web3 = require("web3");
const express = require("express");
const fs = require("fs");
const app = express();
const bodyParser = require("body-parser");
const logger = require("./utils/logger.js");