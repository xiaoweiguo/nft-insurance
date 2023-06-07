/*
 * @Author: Wmengti 0x3ceth@gmail.com
 * @LastEditTime: 2023-06-03 11:02:01
 * @Description: 
 */

const tokenId = args[0];

if (!secrets.openSeaKey) {
  throw Error(
    "Need to set opensea api KEY environment variable"
  )
}


const config = {
  method: 'GET',
  url: `https://api.opensea.io/api/v1/events?token_id=${tokenId}&asset_contract_address=0xED5AF388653567Af2F388E6224dC7C4b3241C544&event_type=successful`,
  timeout:5000,
  maxRedirects: 5,
  headers: {
    'Accept': 'application/json',
    'X-API-KEY': `8d86c5ba1a4d4a868477cbfcf5cd1872`,
  }
};

const response = await Functions.makeHttpRequest(config)
console.log(response)

if (response.error) {
  console.error(
    response.response ? `${response.response.status},${response.response.statusText}` : ""
  )
  throw Error("Request failed")
}

const nftDATA = response.data.data
console.log(nftDATA)
const asset = nftDATA.asset_events[0]
console.log(asset)
console.log(asset.total_price)


return Functions.encodeUint256(asset.total_price)
