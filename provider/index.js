const { OpenSeaStreamClient, Network }= require('@opensea/stream-js');
const  { WebSocket }  = require ('ws');
const { initializeApp }  = require ("firebase/app");
const { getFirestore, Timestamp }  = require ("firebase/firestore");
const { collection, setDoc, addDoc, getDocs, where, query, orderBy, limit }  = require ("firebase/firestore");
const { ethers, utils }  = require ("ethers");
const dotenv  = require ("dotenv");
dotenv.config();
// const { ethers }  = require "hardhat";
const {PRIVKEY, GOERLI_API} = process.env;
const firebaseConfig = require("../firebase-config.json");

const _network = "goerli";
const RevenueBufferAbi  =  require ("../artifacts/contracts/RevenueBuffer.sol/RevenueBuffer.json");
const RevenueBufferAddress = '0xf4102568FeBBbca13C8814501f598080e32A503E';
const HolderPassAbi = require ("../artifacts/contracts/HolderPass.sol/HolderPass.json");
const HolderPassAddress = "0x9EE05d60d3FAf8735e9fd9CC68E3f9F25537Cd84";

const tokenLevelList = [0, 0.01, 0.5, 1.0, 3.0, 5.0]; //ETH for LevelUp of DynamicNFT

const signer = () => {
  const network = ethers.providers.getNetwork(_network);
  const alchemyProvider = new ethers.providers.AlchemyProvider(network, GOERLI_API);
  const signer = new ethers.Wallet(PRIVKEY, alchemyProvider);
  return signer;
}

const getContract = (_signer, address, abi) => {
  const Contract = new ethers.Contract(address, abi.abi, _signer);
  const contractInst = Contract.attach(address);
  return contractInst;
}

const updateRequest = async (tokenId, holderList) => {
  const revenueBuffer = getContract(signer(), RevenueBufferAddress, RevenueBufferAbi);

  // Confirm: setTokenAddress() is ready.
  const address_WETH = await revenueBuffer.WETH();
  console.log("address_WETH:", address_WETH);
  if(address_WETH == "0x00") return;

  try {
    // write
    const tx = await revenueBuffer.addRequest(tokenId, holderList);
    console.log("update tx-hash:", tx.hash);
    await tx.wait();
    // read
    const receiveId = ethers.utils.formatEther(await revenueBuffer.receiveId());
    console.log("current receiveId:", receiveId);
  }catch(e){
    console.error(e);
  }
}

const fetchHolderList = async(tokenId) => {
  const holderPass = getContract(signer(), HolderPassAddress, HolderPassAbi);
  try {
    // const holderList = await holderPass.indexedAccountsByToken(tokenId)
    const holderList = await holderPass.accountsByToken(tokenId);
    return holderList;
  }catch(e){
    console.error(e);
  }
}

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

const getTokenLevel = (price) => {
  var level;
  var tokenLEvelPrice;
  for(var i=0; i<tokenLevelList.length; i++) {
    if (price < tokenLevelList[i]) break;
    level = i +1;
  }
  return level;
}

const sampleEvent = {
    "event_type": "item_sold",
    "sent_at": "2022-04-25T23:32:14.486643+00:00",
    "payload": {
        "event_timestamp": "2022-04-21T16:46:46.240222+00:00",
        "closing_date": "2022-04-21T18:26:36.000000+00:00",
        "is_private": false,
        "listing_type": null,
        "item": {
          "nft_id":"ethereum/0x8a90cab2b38dba80c64b7734e58ee1db38b8992e/222",
          "permalink":"https://opensea.io/assets/0x8a90cab2b38dba80c64b7734e58ee1db38b8992e/222",
          "chain": { "name": "Goerli" },
          "metadata": {
              "name": "Mitama test #1",
              "description": "A community-driven collectibles project featuring art by Burnt Toast. Doodles come...",
              "image_url": "https://lh3.googleusercontent.com/R7wtoDNdmM7GhTvVjr4JGA6q60z44Hn2nIymPjAEXcjnD8oBPxQYPA1GkrCnvepPM1Sc8DlIHZql4Yucj4ger1jnWmxmuRFwIC_JRw",
              "animation_url": null,
              "metadata_url": "https://opensea.mypinata.cloud/ipfs/QmPMc4tcBsMqLRuCQtPmPe84bpSjrC3Ky7t3JWuHXYB4aS/222",
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
        "sale_price": 100000000000000000,
        "taker": { "address": "0x39f3b9C8585Fc57A57EC39322E92Face43484D97" },
        "transaction": {
          "hash": "0x57135fca40b927fbd741f5a21626c1c4c84e7c1036bb50d3158e2fa62a80c941",
          "timestamp": "2022-04-21T18:26:36.000000+00:00"
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
    console.error("Error getItemPriceLastSold:", e);
  }
}

const getItemSoldEvents = async(nft_id) => {
  const itemSoldRef = collection(db, "itemSoldEvent");
  // TODO: Limit(number) needs to be update to 7
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
  // TODO: Limit(number) needs to be update to 7
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
    console.log("update tx-hash:", tx.hash);
    await tx.wait();
  }catch(e){
    console.error(e);
  }
}

// Buyer nees to pay for 1.1x price.
const isPriceRaised = (current, last) => current >= 1.1 * last;
const isLevelRaised =(current, last) => getTokenLevel(current) > getTokenLevel(last);

// run onItemsold
const main = async (event) => {
  const {
    nft_id: tokenId,
    sale_price: currentPrice,
    maker_address: makerAddress
  } = parseItemSoldEvent(event);
  console.log("currentPrice:", currentPrice);
  const priceLastSold = await getItemPriceLastSold(tokenId);

  if(isPriceRaised(currentPrice, priceLastSold)) {
    await injectItem(item);
    // when do we issue the Holder Pass??
    await mintPass(tokenId, makerAddress);
    const holderList = (await fetchHolderList(tokenId)).length !=0
    ? await fetchHolderList(tokenId)
    : await getHolderList(tokenId);
    console.log(holderList);
    await updateRequest(tokenId, holderList);
    // TODO: Call mint of holderPassNFT
    console.log("isLevelRaised", isLevelRaised);
    // when do we issue the Holder Pass??
    // await mintPass(tokenId, makerAddress);
  };

  if(isLevelRaised(currentPrice, priceLastSold)) {
    console.log("token level up!");
    const level = getTokenLevel(currentPrice);
    // call updateTokenLevel(uint256 tikenId, uint8 level) of MitamaNFT
  }
}

// await injectItem(parseItemSoldEvent(sampleEvent));
await main(sampleEvent);

client.onItemSold('mitama-test-1', (e) => main(e));

// if the websocket client is disconnected, automatically try to recoonect it.