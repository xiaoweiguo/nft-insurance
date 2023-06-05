import { EvmChain } from "@moralisweb3/common-evm-utils";
import Moralis from "moralis";

export const fetchNFTs = async address => {
  /*await Moralis.start({
    apiKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJub25jZSI6IjdjNzRlNTY2LWU0ZWQtNDgwNy04YTcwLWYwZmUzNDcyZjkwOCIsIm9yZ0lkIjoiMzQwMTkyIiwidXNlcklkIjoiMzQ5NzI3IiwidHlwZUlkIjoiMzFlMGQ0ZWUtZmRiZS00YThjLTkzZjAtNDNlMGE5NTIyN2JlIiwidHlwZSI6IlBST0pFQ1QiLCJpYXQiOjE2ODU2NzYyNzksImV4cCI6NDg0MTQzNjI3OX0.lY3PRoj2wPd2nXBTc5ckd4ZAjY3G8FMzMiMGdQeMIKs",
    // ...and any other configuration
  });*/
  if (address == undefined) return;

  console.log(8, address);

  const response = await Moralis.EvmApi.nft.getWalletNFTs({
    address,
    chain: EvmChain.MUMBAI,
  });
  //console.log(9, response.raw.result)

  return response.raw.result;
};
