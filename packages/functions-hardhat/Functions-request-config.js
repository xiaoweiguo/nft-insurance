/*
 * @Author: Wmengti 0x3ceth@gmail.com
 * @LastEditTime: 2023-06-03 11:01:01
 * @Description: 
 */
const fs = require("fs")

// Loads environment variables from .env.enc file (if it exists)
require("@chainlink/env-enc").config()
// const source = require("./Functions-request-nft.js");

const Location = {
  Inline: 0,
  Remote: 1,
}

const CodeLanguage = {
  JavaScript: 0,
}

const ReturnType = {
  uint: "uint256",
  uint256: "uint256",
  int: "int256",
  int256: "int256",
  string: "string",
  bytes: "Buffer",
  Buffer: "Buffer",
}

// Configure the request by setting the fields below
const requestConfig = {
  // location of source code (only Inline is curently supported)
  codeLocation: Location.Inline,
  // code language (only JavaScript is currently supported)
  codeLanguage: CodeLanguage.JavaScript,
  // string containing the source code to be executed
  source: fs.readFileSync("./Functions-request-nft.js").toString(),
  // Secrets can be accessed within the source code with `secrets.varName` (ie: secrets.apiKey). The secrets object can only contain string values.
  secrets: {
    openSeaKey: process.env.OPENSEA_API_KEY ?? "",
  },
  // args can be accessed within the source code with `args[index]` (ie: args[0])
  args: ["58"],
  // expected type of the returned value
  expectedReturnType: ReturnType.uint256,
}

module.exports = requestConfig
