import { useState } from "react";
import type { NextPage } from "next";
import { useAccount } from "wagmi";
import { Address, Balance } from "~~/components/scaffold-eth";
import { useNetworkColor } from "~~/hooks/scaffold-eth";
import { getTargetNetwork } from "~~/utils/scaffold-eth";
import { fetchNFTs } from "~~/utils/scaffold-eth";

const Insurance: NextPage = () => {
  const { address } = useAccount();
  const configuredNetwork = getTargetNetwork();
  const networkColor = useNetworkColor();

  const [nfts, setNfts] = useState([]);

  fetchNFTs(address).then(res => {
    //console.log(9, nfts)
    if (res == undefined) return;

    res.map(item => {
      //const n = item.toJSON();

      const n = item;
      if (n["symbol"].substr(0, 5) == "Azuki" && n["metadata"] != null) {
        n["metadata"] = JSON.parse(n["metadata"]);
        nfts.push(n);
        console.log(6, n);
        setNfts(nfts);
      }
    });
  });

  const listItems = nfts.map(nft => (
    <li key={nft.tokenHash}>
      {nft.metadata.name} ({nft.tokenId})
    </li>
  ));

  //console.log(7, allnfts)
  return (
    <>
      <div className="flex flex-col gap-y-6 lg:gap-y-8 py-8 lg:py-12 justify-center items-center">
        <div className={`grid grid-cols-1 lg:grid-cols-6 px-6 lg:px-10 lg:gap-12 w-full max-w-7xl my-0`}>
          <div className="col-span-5 grid grid-cols-1 lg:grid-cols-3 gap-8 lg:gap-10">
            <div className="col-span-1 flex flex-col">
              <div className="bg-base-100 border-base-300 border shadow-md shadow-secondary rounded-3xl px-6 lg:px-8 mb-6 space-y-1 py-4">
                <div className="flex">
                  <div className="flex flex-col gap-1">
                    <Address address={address} />
                    <div className="flex gap-1 items-center">
                      <span className="font-bold text-sm">Balance:</span>
                      <Balance address={address} className="px-0 h-1.5 min-h-[0.375rem]" />
                    </div>
                  </div>
                </div>
                {configuredNetwork && (
                  <p className="my-0 text-sm">
                    <span className="font-bold">Network</span>:{" "}
                    <span style={{ color: networkColor }}>{configuredNetwork.name}</span>
                  </p>
                )}
              </div>
              <div className="bg-base-300 rounded-3xl px-6 lg:px-8 py-4 shadow-lg shadow-base-300">
                {nfts.length === 0 ? <p className="text-1xl mt-14">No Azuki found!</p> : <ul>{listItems}</ul>}
              </div>
            </div>
          </div>
        </div>
      </div>
      <div className="text-center mt-8 bg-secondary p-10">
        <h1 className="text-4xl my-0">Debug Contracts</h1>
        <p className="text-neutral">
          You can debug & interact with your deployed contracts here.
          <br /> Check{" "}
          <code className="italic bg-base-300 text-base font-bold [word-spacing:-0.5rem] px-1">
            packages / nextjs / pages / debug.tsx
          </code>{" "}
        </p>
      </div>
    </>
  );
};

export default Insurance;
