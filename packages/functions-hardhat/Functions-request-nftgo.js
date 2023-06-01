/*
 * @Author: Wmengti 0x3ceth@gmail.com
 * @LastEditTime: 2023-05-27 12:55:29
 * @Description: 
 */

const nftID = args[0];

if (!secrets.nftgoKey) {
  throw Error(
    "Need to set NFTGOKEY environment variable"
  )
}



const config = {
  method: 'GET',
  url: `https://data-api.nftgo.io/eth/v1/nft/0xED5AF388653567Af2F388E6224dC7C4b3241C544/${nftID}/info`,
  headers: {
    'Accept': 'application/json',
    'X-API-KEY': `${secrets.nftgoKey}`,
  }
};

const response = await Functions.makeHttpRequest(config)
