// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

interface IERC20Token {
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Carparking {

    uint internal parkingSlot = 10;
    uint256 internal parkingFee = 1 * 10 ** 18;
    uint internal carsAmount = 0;
    uint256 MAX_INT = 2**256 - 1;

    address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;
    address internal parkingOwnerCusdTokenAddress = 0x40273BA6c425Aa745c938e581D05C8D67eD7F06C;

    struct ParkingCar {
        address payable carOwner;
        string carNumber;
        string carImage;
        bool isParked;
    }

    mapping (string => ParkingCar) internal parkingCars;
    ParkingCar[] parkingCarList;

    function parking(string memory _carNumber, string memory _carImage) public {
        require(carsAmount < parkingSlot, "No parking slot!");
        if(carsAmount > 0) {
            require(parkingCars[_carNumber].isParked == false, "Car was parked!");
        }

        uint emptySlot = getEmptySlot();

        if(emptySlot == MAX_INT) {
            parkingCarList.push(ParkingCar(
                    payable(msg.sender),
                    _carNumber,
                    _carImage,
                    true
                ));
        } else {
            parkingCarList[emptySlot] = ParkingCar(
                payable(msg.sender),
                _carNumber,
                _carImage,
                true
            );
        }

        parkingCars[_carNumber] = ParkingCar(
            payable(msg.sender),
            _carNumber,
            _carImage,
            true
        );
        carsAmount++;
    }

    function getEmptySlot() internal view returns(uint) {
        for (uint256 i = 0; i < parkingCarList.length; i++){
            if(parkingCarList[i].isParked == false) {
                return i;
            }
        }
        return MAX_INT;
    }

    function getParkingCar(uint _index) public view returns (address payable,
        string memory,
        string memory) {
        return (
        parkingCarList[_index].carOwner,
        parkingCarList[_index].carNumber,
        parkingCarList[_index].carImage
        );
    }

    function unParking(string memory _carNumber) public payable {
        require(parkingCars[_carNumber].carOwner == msg.sender, "Invalid parking car!");
        require(
            IERC20Token(cUsdTokenAddress).transferFrom(
                msg.sender
            ,parkingOwnerCusdTokenAddress
            ,parkingFee
            ),
            "Transfer fee failed."
        );
        delete(parkingCars[_carNumber]);
        for (uint256 i = 0; i < parkingCarList.length; i++){
            if (keccak256(abi.encodePacked(parkingCarList[i].carNumber)) == keccak256(abi.encodePacked(_carNumber))) {
                delete(parkingCarList[i]);
            }
        }
        carsAmount--;
    }

    function getAllParkingCar() public view returns (ParkingCar[] memory parkingCar) {
        return parkingCarList;
    }

    function getCarsAmount() public view returns (uint) {
        return (carsAmount);
    }

    function getParkingFee() public view returns (uint256) {
        return (parkingFee);
    }

    function getParkingSlotNumber() public view returns (uint) {
        return (parkingSlot);
    }
}