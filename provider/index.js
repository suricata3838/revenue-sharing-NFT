const { OpenSeaStreamClient, Network }= require('@opensea/stream-js');
const  { WebSocket }  = require ('ws');
const { initializeApp }  = require ("firebase/app");
const { getFirestore, Timestamp }  = require ("firebase/firestore");
const { collection, setDoc, addDoc, getDocs, where, query, orderBy, limit }  = require ("firebase/firestore");
const { ethers, utils }  = require ("ethers");

const dotenv  = require ("dotenv");
dotenv.config();
// const { ethers }  = require "hardhat";
const {PRIVKEY, GOERLI_API, GOERLI_APIKEY} = process.env;
const firebaseConfig = require("../firebase-config.json");

const _network = "goerli";
const MitamaAbi = require("../artifacts/contracts/active/Mitama.sol/Mitama.json");
const MitamaAddress = '0x40f5434cbED8ac30a0A477a7aFc569041B3d2012'
const RevenueShareAbi  =  require ("../artifacts/contracts/active/RevenueShare.sol/RevenueShare.json");
const RevenueShareAddress = '0x811BC1fFC4a198F90193D91729ca4ab90241E940';
const RevenueShareForDonationAbi = require ("../artifacts/contracts/active/RevenueShareForDonation.sol/RevenueShareForDonation.json");
const RevenueShareForDonationAddress = '0x1CDE6E7f0BB09FFD40e366cAd206a663D81614b3';
const HolderPassAbi = require ("../artifacts/contracts/active/HolderPass.sol/HolderPass.json");
const HolderPassAddress = '0xA26cdC2B089a36FF722d76969b96A4AD8D4E6930';
// on Ethereum mainnet
const WETH_Address = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2';

const tokenLevelList = [0, 0.01, 0.5, 1.0, 3.0, 5.0]; //ETH for LevelUp of DynamicNFT

const signer = () => {
  const network = ethers.providers.getNetwork(_network);
  const alchemyProvider = new ethers.providers.AlchemyProvider(network, GOERLI_APIKEY);
  const signer = new ethers.Wallet(PRIVKEY, alchemyProvider);
  return signer;
}

const getContract = (_signer, address, abi) => {
  const contractInst = new ethers.Contract(address, abi.abi, _signer);
  const contractInstAddr = contractInst.attach(address);
  return contractInstAddr;
}

const updateRequest = async (tokenId, holderList) => {
  const revenueShare = getContract(signer(), RevenueShareAddress, RevenueShareAbi);

  // Confirm: setTokenAddress() is ready.
  const address_WETH = await revenueShare.WETH();
  if(address_WETH == '0x00') {
  // Revert becourse of "failed setWETH()"
    const tx = await revenueShare.setWETH(WETH_Address);
    console.log("setWETH txHash:", tx.hash);
    await tx.wait();    
  }

  try {
    // write
    // Error: "execution reverted: request amount should be > 0"
    // TODO: send ETH to the revenueShare
    const tx = await revenueShare.addRequest(tokenId, holderList);
    console.log("addRequest txHash:", tx.hash);
    await tx.wait();
    // read
    const receiveId = (await revenueShare.receiveId()).toString();
    console.log("receiveId:", receiveId);
    return receiveId ? receiveId : 0;
  }catch(e){
    console.log("Error:", e.code, ":", e.reason)
    console.log(JSON.parse(e.error.error.body).error.message)
  }
}

const updateRequestForDonation = async (tokenId) => {
  const revenueShareForDonation = getContract(signer(), RevenueShareForDonationAddress, RevenueShareForDonationAbi);

  // Confirm: setTokenAddress() is ready.
  const address_WETH = await revenueShareForDonation.WETH();
  if(address_WETH == '0x00') {
    console.log("address_WETH:", address_WETH);
    const tx = await revenueShareForDonation.setWET(WETH_Address);
    console.log("Donaiton setWET tx-hash:", tx.hash);
    await tx.wait();    
  }

  try {
    // write
    const tx = await revenueShareForDonation.addRequest(tokenId);
    console.log("Donation addRequest txhash:", tx.hash);
    await tx.wait();
    // read
    const receiveId = (await revenueShareForDonation.receiveId()).toString();
    console.log("receiveId:", receiveId);
  }catch(e){
    console.log("Error:", e.code, ":", e.reason)
    console.log(JSON.parse(e.error.error.body).error.message)
  }
}

const fetchHolderList = async(tokenId) => {
  const holderPass = getContract(signer(), HolderPassAddress, HolderPassAbi);
  try {
    const totalHolders = (await holderPass.totalHolders(tokenId)).toString();
    if(totalHolders > 0) {
      const holderList = await holderPass.indexedAccountsByToken(tokenId);
      if(holderList.length == 0) return 0;
      return holderList;
    }
    return 0;
  }catch(e){
    console.log("Error:", e.code, ":", e.reason)
    console.log(JSON.parse(e.error.error.body).error.message)
  }
}

const getTokenLevel = (price) => {
  var level;
  var tokenLEvelPrice;
  for(var i=0; i<tokenLevelList.length; i++) {
    if (price < tokenLevelList[i]) break;
    level = i +1;
  }
  return level;
}

// TODO: Update "sale_price"
const getEvent = (id, price) => {
    return {"event_type": "item_sold",
    "sent_at": "2022-04-25T23:32:14.486643+00:00",
    "payload": {
        "event_timestamp": "2022-04-21T16:46:46.240222+00:00",
        "closing_date": "2022-04-21T18:26:36.000000+00:00",
        "is_private": false,
        "listing_type": null,
        "item": {
          "nft_id":`ethereum/0x8a90cab2b38dba80c64b7734e58ee1db38b8992e/${id}`,
          "permalink":`https://opensea.io/assets/0x8a90cab2b38dba80c64b7734e58ee1db38b8992e/${id}`,
          "chain": { "name": "Goerli" },
          "metadata": {
              "name": "Mitama test #1",
              "description": "A community-driven collectibles project featuring art by Burnt Toast. Doodles come...",
              "image_url": "https://lh3.googleusercontent.com/R7wtoDNdmM7GhTvVjr4JGA6q60z44Hn2nIymPjAEXcjnD8oBPxQYPA1GkrCnvepPM1Sc8DlIHZql4Yucj4ger1jnWmxmuRFwIC_JRw",
              "animation_url": null,
              "metadata_url": `https://opensea.mypinata.cloud/ipfs/QmPMc4tcBsMqLRuCQtPmPe84bpSjrC3Ky7t3JWuHXYB4aS/${id}`,
          },
        },
        "maker": { "address": "0xcDe7a88a1dada60CD5c888386Cc5C258D85941Dd" },
        "payment_token": {
          "address": "0x7ceb23fd6bc0add59e62ac25578270cff1b9f619",
          "decimals": 18,
          "eth_price": "0.01",
          "name": "WrappedEther",
          "symbol": "WETH",
          "usd_price": "3067.19"
        },
        "quantity": 1,
        "sale_price": price * 10 ** 18,
        "taker": { "address": "0x39f3b9C8585Fc57A57EC39322E92Face43484D97" },
        "transaction": {
          "hash": "0x57135fca40b927fbd741f5a21626c1c4c84e7c1036bb50d3158e2fa62a80c941",
          "timestamp": "2022-04-21T18:26:36.000000+00:00"
        }
    }
  }
}
const parseItemSoldEvent = (event) => {
  const payload = event.payload;
  const nft_id = payload.item.nft_id.split('/')[2];
  const sale_price = parseFloat(utils.formatEther(String(payload.sale_price)));//string ETH
  const maker_address = payload.maker.address;
  const taker_address = payload.taker.address;
  const timestamp = Timestamp.now();
  return {
    nft_id,
    sale_price,
    maker_address,
    taker_address,
    timestamp
  };
};

const injectItem = async (item) => {
  // const item = parseItemSoldEvent(event);
  try {
    const docRef = await addDoc(collection(db, "itemSoldEvent"), item);
    console.log("injectItem: ", docRef.id);
  } catch (e) {
    console.error("Error injectItem: ", e);
  }
};

const isItemPriceRaised = async (nft_id, currentPrice) => {
  const priceLastSold = await getItemPriceLastSold(nft_id);
  const lastLevel = getTokenLevel(priceLastSold);
  return parseFloat(currentPrice) > parseFloat(priceLastSold);
}

const getItemPriceLastSold = async(nft_id) => {
  const itemSoldRef = collection(db, "itemSoldEvent");
  const q = query(itemSoldRef, where("nft_id", "==", nft_id), orderBy("sale_price", "desc"), limit(1));
  try{
    const querySnapshot = await getDocs(q);
    var sale_price;
    querySnapshot.forEach((doc) => {
      if(!doc.data()) return null;
      // doc.data() is never undefined for query doc snapshots
      console.log("pre sale_price", doc.data()["sale_price"]);
      sale_price = doc.data()["sale_price"];
    });
    return sale_price ? sale_price : null;
   } catch(e) {
    console.log("Error:", e.code, ":", e.reason)
    console.log(JSON.parse(e.error.error.body).error.message)
  }
}

const getItemSoldEvents = async(nft_id) => {
  const itemSoldRef = collection(db, "itemSoldEvent");
  const q = query(itemSoldRef, where("nft_id", "==", nft_id), orderBy("sale_price", "desc"), limit(3));
  try {
    const querySnapshot = await getDocs(q);
    querySnapshot.forEach((doc) => {
    // doc.data() is never undefined for query doc snapshots
    });
  } catch (e) {
    console.error("Error getting document: ", e);
  }
}

const getHolderList = async(tokenId) => {
  const itemSoldRef = collection(db, "itemSoldEvent");
  const q = query(itemSoldRef, where("nft_id", "==", tokenId), orderBy("sale_price", "desc"), limit(7));
  try {
    const querySnapshot = await getDocs(q);
    var holderAddressList= [];
    querySnapshot.forEach((doc) => {
      holderAddressList.push(doc.data()["maker_address"]);
    });
    return holderAddressList;
  } catch (e) {
    console.error("Error getHolderList:", e);
  }
}

const mintPass = async(tokenId, accountTo) => {
  const holderPass = getContract(signer(), HolderPassAddress, HolderPassAbi);
  try {
    // const holderList = await holderPass.indexedAccountsByToken(tokenId)
    const tx = await holderPass.mintPass(accountTo, tokenId);
    console.log("update txHash:", tx.hash);
    await tx.wait();
  }catch(e){
    console.log("Error:", e.code, ":", e.reason)
    console.log(JSON.parse(e.error.error.body).error.message)
  }
}

const updateTokenLevel = async(tokenId, level) => {
    const NFT = getContract(signer(), TestDAWLNFTAddress, TestDAWLNFTAbi);
    try {
      const tx = await NFT.updateAuraLevel(tokenId, level);
      console.log("token level-up txHash:", tx.hash);
      await tx.wait();
    }catch(e){
      console.log("Error:", e.code, ":", e.reason)
      console.log(JSON.parse(e.error.error.body).error.message)
    }
}

const sendETHToAddr = async(_addr) => {
    const amountInEther = '0.001'
    let tx = {
        to: _addr,
        value: ethers.utils.parseEther(amountInEther)
    }
    try {
      const res = await signer().sendTransaction(tx)
      console.log("sendEth:", res.hash)
      return res
    } catch(e) {
      console.log("Error:", e.code, ":", e.reason)
      console.log(JSON.parse(e.error.error.body).error.message)
    }
}

// Buyer nees to pay for 1.1x price.
const isPriceRaised = (current, last) => current >= 1.1 * last;
const isLevelRaised =(current, last) => getTokenLevel(current) > getTokenLevel(last);

// run onItemsold
const main = async (event) => {
  await sendETHToAddr(RevenueShareAddress);
  await sendETHToAddr(RevenueShareForDonationAddress);

  const {
    nft_id: tokenId,
    sale_price: currentPrice,
    maker_address: makerAddress
  } = parseItemSoldEvent(event);
  const priceLastSold = await getItemPriceLastSold(tokenId);
  console.log("current-vs-pre:", currentPrice, " vs ", priceLastSold);
  //if(isPriceRaised(currentPrice, priceLastSold)) {
  if(true){
    await injectItem(parseItemSoldEvent(event));
    const fetchedHolderList = await fetchHolderList(tokenId);
    console.log("holderLength:", fetchedHolderList.length)
    const holderList = fetchedHolderList.length > 0 ? fetchedHolderList : await getHolderList(tokenId);
    console.log("holderList:", holderList);
    await updateRequest(tokenId, holderList);
    await updateRequestForDonation(tokenId);
    /* PassHolder will get the royalty at the next round of itemSold event, not this round. */
    await mintPass(tokenId, makerAddress);
  };

  console.log("isLevelRaised", isLevelRaised(currentPrice, priceLastSold));
  // if(isLevelRaised(currentPrice, priceLastSold)) {
  if(true){
    const level = getTokenLevel(currentPrice);
    console.log("current level:", level);
    await updateTokenLevel(tokenId, level);// call updateTokenLevel(uint256 tikenId, uint8 level) of MitamaNFT
  }
}

// await injectItem(parseItemSoldEvent(sampleEvent));

/**
 * App Initialization, webcoket
 */
// Initialize Firebase
const app = initializeApp(firebaseConfig);
// Initialize Cloud Firestore and get a reference to the service
const db = getFirestore(app);

const client = new OpenSeaStreamClient({
    token: 'openseaApiKey',
    network: Network.TESTNET,
    connectOptions: {
      transport: WebSocket
    }
  });

main(getEvent(0, 0.51));

/**
 * Event Watcher to watch onItemSold of Opensea
 */
// client.onItemSold('daerc721', (e) => main(e));

// onEvent: WETH is transfered to this contract
// run revenueShare.getWETHbalance();
// run revenueShareForDonation.getWETHbalance();

// If the websocket client is disconnected, automatically try to recoonect it.