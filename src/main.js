import Web3 from 'web3'
import {newKitFromWeb3} from '@celo/contractkit'
import BigNumber from "bignumber.js"
import carparkingAbi from '../contract/carparking.abi.json'
import erc20Abi from "../contract/erc20.abi.json"
import {none} from "html-webpack-plugin/lib/chunksorter";

const ERC20_DECIMALS = 18
const CPContractAddress = "0x326df4A964Bee6B8fDB5730B312f15D41351eb94"
const cUSDContractAddress = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1"
let kit
let parkingFee
let parkingSlot
let carsAmount
let contract
let cars = []

const connectCeloWallet = async function () {
  if (window.celo) {
    notification("⚠️ Please approve this DApp to use it.")
    try {
      await window.celo.enable()
      notificationOff()

      const web3 = new Web3(window.celo)
      kit = newKitFromWeb3(web3)

      const accounts = await kit.web3.eth.getAccounts()
      kit.defaultAccount = accounts[0]

      contract = new kit.web3.eth.Contract(carparkingAbi, CPContractAddress)

    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
  } else {
    notification("⚠️ Please install the CeloExtensionWallet.")
  }
}

async function approve() {
  const cUSDContract = new kit.web3.eth.Contract(erc20Abi, cUSDContractAddress)

  const result = await cUSDContract.methods
                                   .approve(CPContractAddress, new BigNumber(parkingFee))
                                   .send({ from: kit.defaultAccount })
  return result
}

const getBalance = async function () {
  const totalBalance = await kit.getTotalBalance(kit.defaultAccount)
  document.querySelector("#balance").textContent = totalBalance.cUSD.shiftedBy(-ERC20_DECIMALS).toFixed(2)
}

const getParkingFee = async function () {
  parkingFee = await contract.methods.getParkingFee().call()
  document.querySelector("#parkingFee").textContent = new BigNumber(parkingFee).shiftedBy(-ERC20_DECIMALS).toFixed(2)
}

const getParkingSlot = async function () {
  parkingSlot = await contract.methods.getParkingSlotNumber().call()
}

const getCarsAmount = async function () {
  carsAmount = await contract.methods.getCarsAmount().call()
}

const getParkingCars = async function () {
  const _cars = await contract.methods.getAllParkingCar().call()
  const _tempCars = []

  for(let i = 0;i < _cars.length;i++) {
    let _car = {
      index: i,
      carOwner: _cars[i].carOwner,
      carNumber: _cars[i].carNumber,
      carImage: _cars[i].carImage,
      isParked: _cars[i].isParked,
    }
    _tempCars.push(_car)
  }
  cars = await Promise.all(_tempCars)
  renderParkingCars()
}

function renderParkingCars() {
  document.getElementById("carparkingplace").innerHTML = ""
  cars.forEach((_car) => {
    if(_car.isParked && _car.carOwner === kit.defaultAccount) {
      const newDiv = document.createElement("div")
      newDiv.className = "col-md-4"
      newDiv.innerHTML = carTemplate(_car)
      document.getElementById("carparkingplace").appendChild(newDiv)
    }
  })
}

function carTemplate(_car) {
    return `
    <div class="card mb-4">
      <img class="card-img-top" src="${_car.carImage}" alt="...">
      <div class="card-body text-left p-4 position-relative">
        <div class="translate-middle-y position-absolute top-0">
        ${identiconTemplate(_car.carOwner)}
        </div>
        <h2 class="card-title fs-4 fw-bold mt-2">Car number: ${_car.carNumber}</h2>
        <div class="d-grid gap-2">
          <a class="btn btn-lg btn-outline-dark unParkBtn fs-6 p-3" id=${_car.index}>
            Unpark
          </a>
        </div>
      </div>
    </div>
  `
}

function identiconTemplate(_address) {
  const icon = blockies
    .create({
      seed: _address,
      size: 8,
      scale: 16,
    })
    .toDataURL()

  return `
  <div class="rounded-circle overflow-hidden d-inline-block border border-white border-2 shadow-sm m-0">
    <a href="https://alfajores-blockscout.celo-testnet.org/address/${_address}/transactions"
        target="_blank">
        <img src="${icon}" width="48" alt="${_address}">
    </a>
  </div>
  `
}

function notification(_text) {
  document.querySelector(".alert").style.display = "block"
  document.querySelector("#notification").textContent = _text
}

function notificationOff() {
  document.querySelector(".alert").style.display = "none"
}

window.addEventListener("load", async () => {
  notification("⌛ Loading...")
  await connectCeloWallet()
  await getBalance()
  await getParkingFee()
  await getParkingCars()
  await getParkingSlot()
  await getCarsAmount()
  if(carsAmount === parkingSlot) {
    document.querySelector("#parkCarBtn").style.pointerEvents = "none"
    notification(`⚠️ Out of parking slot.`)
  }
  else {
      notificationOff()
  }
})

document
  .querySelector("#newCarBtn")
  .addEventListener("click", async (e) => {
    const params = [
      document.getElementById("newCarNumber").value,
      document.getElementById("newImgUrl").value
    ]
    notification(`⌛ Parking "${params[0]}"...`)
    try {
      const result = await contract.methods
        .parking(...params)
        .send({from: kit.defaultAccount})
      notification(`🎉 You successfully parked "${params[0]}".`)
    } catch (error) {
      console.log(error)
      notification(`⚠️ Parked a car failed.`)
    }
    await getBalance()
    await getParkingSlot()
    await getCarsAmount()
    await getParkingCars()
    if(carsAmount === parkingSlot) {
      document.querySelector("#parkCarBtn").style.pointerEvents = "none"
      notification(`⚠️ Out of parking slot.`)
    }
  })

document.querySelector("#carparkingplace").addEventListener("click",  async (e) => {
  if(e.target.className.includes("unParkBtn")) {
    const index = e.target.id
    notification("⌛ Waiting for payment approval...")
    try{
      await approve()
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
    notification(`⌛ Awaiting payment for "${cars[index].carNumber}"...`)
    try {
      const result = await contract.methods.unParking(cars[index].carNumber)
        .send({from: kit.defaultAccount})
      notification(`🎉 You successfully unparked "${cars[index].carNumber}".`)
      await getParkingCars()
      await getBalance()
      await getParkingFee()
      await getParkingSlot()
      await getCarsAmount()
      if(carsAmount < parkingSlot) {
        document.querySelector("#parkCarBtn").style.pointerEvents = ""
      }
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
  }
})