const tokenId = args[0];

// Check if the OpenSea API key is set
if (!secrets.openSeaKey) {
  throw Error("Need to set OpenSea API KEY environment variable");
}

// Define the configuration for the HTTP request to the OpenSea API
//${insurance_end/begin_time} format:2022-01-21 00:00:00
//asset_contract_address: Azuki address
const config = {
  method: 'GET',
  url: `https://api.opensea.io/api/v1/events?token_id=${tokenId}&asset_contract_address=0xED5AF388653567Af2F388E6224dC7C4b3241C544&account_address=${nft_holder_openseaaccount_adress}
  &event_type=successful&occurred_before=${insurance_end_time}&occurred_after=${insuranc_begin_time}`,
  timeout: 5000,
  maxRedirects: 5,
  headers: {
    'Accept': 'application/json',
    'X-API-KEY': `8d86c5ba1a4d4a868477cbfcf5cd1872`,
  }
};

// Make the HTTP request to the OpenSea API
const response = await Functions.makeHttpRequest(config);

console.log(response);

// Check for errors in the response
if (response.error) {
  console.error(response.response ? `${response.response.status},${response.response.statusText}` : "");
  throw Error("Request failed");
}

const nftDATA = response.data.data;

console.log(nftDATA);

const asset = nftDATA.asset_events[0];

console.log(asset);
console.log(asset.total_price);

return Functions.encodeUint256(asset.total_price);

// Withdraw asset information for successful transactions
const asset = nftDATA.asset_events[0];
console.log(asset);

// Define an object or array to store the token_price variable
const tokenPrices = {
  token_price_1: asset.token_price_1,
  token_price_2: asset.token_price_2,
  token_price_3: asset.token_price_3,
  // ...more 
};

// The initialization variable is used to store the valid token_price when the condition is met.
let validTokenPrice = null;

// Iterate through each property in the tokenPrices object and find the first value that is not null
for (const priceKey in tokenPrices) {
  const price = tokenPrices[priceKey];
  if (price !== null) {
    validTokenPrice = price;
    break;
  }
}

// Check if validTokenPrice is null
if (validTokenPrice === null) {
  throw Error("No valid token price found");
}

console.log(validTokenPrice);

return Functions.encodeUint256(validTokenPrice);
