// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

interface IERC20Token {
    function transfer(address, uint256) external returns (bool);

    function approve(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Carparking {
    uint internal parkingSlot = 10;
    uint256 internal parkingFee = 1 ether;
    uint internal carsAmount = 0;
    uint public allTimeParked = 0;
    uint256 MAX_INT = 2**256 - 1;

    address internal cUsdTokenAddress =
        0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;
    address internal parkingOwnerCusdTokenAddress =
        0x40273BA6c425Aa745c938e581D05C8D67eD7F06C;

    struct ParkingCar {
        address payable carOwner;
        string carNumber;
        string carImage;
        bool isParked;
    }

    mapping(uint => ParkingCar) internal parkingCars;
    mapping(string => bool) public isParked;

    /**
     * @dev allows users to park a car
     * @notice getEmptySlot retrieves a parking slot that is now vacant after being previously used
     */
    function parking(string memory _carNumber, string memory _carImage) public {
        require(carsAmount < parkingSlot, "No parking slot!");
        require(bytes(_carNumber).length > 0, "Empty car number");
        require(bytes(_carImage).length > 0, "Empty car image");
        require(!isParked[_carNumber], "Car is currently parked");

        uint emptySlot = getEmptySlot();
        if (emptySlot == MAX_INT) {
            parkingCars[carsAmount] = ParkingCar(
                payable(msg.sender),
                _carNumber,
                _carImage,
                true
            );
            carsAmount++;
        } else {
            parkingCars[emptySlot] = ParkingCar(
                payable(msg.sender),
                _carNumber,
                _carImage,
                true
            );
        }
        isParked[_carNumber] = true;
        allTimeParked++;
    }

    /**
     * @dev retrieves a parking slot that is vacant
     * @notice returns the maximum value allowed for uint if no initialised parking slot is free
     */
    function getEmptySlot() internal view returns (uint) {
        for (uint256 i = 0; i < carsAmount; i++) {
            if (parkingCars[i].isParked == false) {
                return i;
            }
        }
        return MAX_INT;
    }

    function getParkingCar(uint _index)
        public
        view
        returns (
            address payable,
            string memory,
            string memory,
            bool
        )
    {
        return (
            parkingCars[_index].carOwner,
            parkingCars[_index].carNumber,
            parkingCars[_index].carImage,
            isParked[parkingCars[_index].carNumber]
        );
    }

    /**
     * @dev allows users to unpark their car
     */
    function unPark(uint _index) public payable {
        require(
            parkingCars[_index].carOwner == msg.sender,
            "Invalid parking car!"
        );
        require(parkingCars[_index].isParked, "Car isn't parked");
        require(
            IERC20Token(cUsdTokenAddress).transferFrom(
                msg.sender,
                parkingOwnerCusdTokenAddress,
                parkingFee
            ),
            "Transfer fee failed."
        );
        isParked[parkingCars[_index].carNumber] = false;
        parkingCars[_index].isParked = false;
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
