const { OpenSeaStreamClient, Network }= require('@opensea/stream-js');
const  { WebSocket }  = require ('ws');
const { initializeApp }  = require ("firebase/app");
const { getFirestore, Timestamp }  = require ("firebase/firestore");
const { collection, setDoc, addDoc, getDocs, where, query, orderBy, limit }  = require ("firebase/firestore");
const { ethers, utils }  = require ("ethers");
const dotenv  = require ("dotenv");
dotenv.config();
// const { ethers }  = require "hardhat";
const abi  =  require ("../artifacts/contracts/RevenueBuffer.sol/RevenueBuffer.json");


const updateRequest = async (tokenId, members) => {
  // get deployer(Admin) address of revenuBuffer contract
  const deployer = process.env.DEPLOYER;
  // deployed RevenueBuffer contract address on Rinkeby
  const address = '0xf4102568FeBBbca13C8814501f598080e32A503E';
  // Provider
  const network = ethers.providers.getNetwork("rinkeby");
  const alchemyProvider = new ethers.providers.AlchemyProvider(network, process.env.APIKEY);
  // Signer(deployer address derived from PRIVKEY)
  const signer = new ethers.Wallet(process.env.PRIVKEY, alchemyProvider);
  // get contract instancess
  const RevenueBuffer = await new ethers.Contract(address, abi.abi, signer);
  const revenueBuffer = await RevenueBuffer.attach(address);
  // Confirm: setTokenAddress() is ready.
  const address_WETH = await revenueBuffer.WETH();
  console.log("address_WETH:", address_WETH);
  if(address_WETH == "0x00") return;

  try {
    // Write contract
    const tx = await revenueBuffer.addRequest(tokenId, members);
    console.log("update tx-hash:", tx.hash);
    await tx.wait();
    // Read contract
    const receiveId = ethers.utils.formatEther(await revenueBuffer.receiveId());
    console.log("current receiveId:", receiveId);
  }catch(e){
    console.error(e);
  }
}

const firebaseConfig = {
  apiKey: "AIzaSyC0pHf0Zbw53XEJgMmZjSQUiOMlgbZ1oFU",
  authDomain: "mitama-solditem-history.firebaseapp.com",
  projectId: "mitama-solditem-history",
  storageBucket: "mitama-solditem-history.appspot.com",
  messagingSenderId: "136704517269",
  appId: "1:136704517269:web:5a633f81189e39dbda279c"
};

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

const tokenLevelList = [0, 0.01, 0.5, 1.0, 3.0, 5.0]; //ETH for LevelUp of DynamicNFT
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
          "chain": { "name": "Rinkeby" },
          "metadata": {
              "name": "Mitama test #1",
              "description": "A community-driven collectibles project featuring art by Burnt Toast. Doodles come...",
              "image_url": "https://lh3.googleusercontent.com/R7wtoDNdmM7GhTvVjr4JGA6q60z44Hn2nIymPjAEXcjnD8oBPxQYPA1GkrCnvepPM1Sc8DlIHZql4Yucj4ger1jnWmxmuRFwIC_JRw",
              "animation_url": null,
              "metadata_url": "https://opensea.mypinata.cloud/ipfs/QmPMc4tcBsMqLRuCQtPmPe84bpSjrC3Ky7t3JWuHXYB4aS/222",
          },
        },
        "maker": { "address": "0x9e7b8c91eca1139c41eead94eeb8bc21bd2725ab" },
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
        "taker": { "address": "0x338571a641d8c43f9e5a306300c5d89e0cb2cfaf" },
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

const getItemHolderList = async(nft_id) => {
  const itemSoldRef = collection(db, "itemSoldEvent");
  // TODO: Limit(number) needs to be update to 7
  const q = query(itemSoldRef, where("nft_id", "==", nft_id), orderBy("sale_price", "desc"), limit(7));
  try {
    const querySnapshot = await getDocs(q);
    var holderAddressList= [];
    querySnapshot.forEach((doc) => {
      holderAddressList.push(doc.data()["maker_address"]);
    });
    return holderAddressList;
  } catch (e) {
    console.error("Error getItemHolderList:", e);
  }
}

// run onItemosld
const main = async (event) => {
  const item = parseItemSoldEvent(event);
  const tokenId = item.nft_id;
  const currentPrice = item.sale_price;
  const makerAddress = item.maker_address;
  console.log("currentPrice:", currentPrice);
  const priceLastSold = await getItemPriceLastSold(item.nft_id);
  const isPriceRaised = currentPrice >= 1.1 * priceLastSold; // Buyer nees to pay for 1.1x price. 
  console.log("level:", getTokenLevel(currentPrice), "<=", getTokenLevel(priceLastSold));
  const isLevelRaised = getTokenLevel(currentPrice) > getTokenLevel(priceLastSold);
  console.log("isPriceRaised", isPriceRaised);
  if(isPriceRaised) {
    await injectItem(item);
    const holderAddressList = await getItemHolderList(item.nft_id);
    console.log(holderAddressList);
    await updateRequest(tokenId, holderAddressList);
    // call mint of holderPassNFT
    console.log("isLevelRaised", isLevelRaised);
  };
  if(isLevelRaised) {
    console.log("token level up!");
    const level = getTokenLevel(currentPrice);
    // call updateTokenLevel(uint256 tikenId, uint8 level) of MitamaNFT
  }
}

// await injectItem(parseItemSoldEvent(sampleEvent));
// await main(sampleEvent);

// client.onItemSold('henohenomoheji', (e) => main(e));
client.onItemSold('mitama-test-1', (e) => main(e));