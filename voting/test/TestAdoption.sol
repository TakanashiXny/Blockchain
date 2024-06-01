// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

import "truffle/Assert.sol"; // 引入新的断言
import "truffle/DeployedAddresses.sol"; // 用来获取被测试合约的地址
import "../contracts/Adoption.sol"; // 被测试合约

contract TestAdoption {
    Adoption adoption = Adoption(DeployedAddresses.Adoption());

    // 领养测试用例
    function testUserCanAdoptPet() public {
        uint returnedId = adoption.adopt(8);

        uint expected = 8;
        Assert.equal(returnedId, expected, "Adoption of pet ID 8 should be recorded.");
    }

    // 宠物所有者测试用例
    function testGetAdopterAddressByPetId() public {
        // 期望领养者的地址就是本合约的地址，因为交易是由测试合约发起交易
        address expected = address(this);
        address adopter = adoption.adopters(8);

        Assert.equal(adopter, expected, "Owner of pet ID 8 should be recorded");
    }

    // 测试所有领养者
    function testGetAdopterAddressByPetIdInArray() public {
        // 领养者的地址就是本合约的地址
        address expected = address(this);
        address[16] memory adopters = adoption.getAdopters();
        Assert.equal(adopters[8], expected, "Owner of pet ID 8 should be recorded");
    }
}

// pragma solidity ^0.5.0;

// import "truffle/Assert.sol";
// import "truffle/DeployedAddresses.sol";
// import "../contracts/Adoption.sol";

// contract TestAdoption {
//   // The address of the adoption contract to be tested
//   Adoption adoption = Adoption(DeployedAddresses.Adoption());

//   // The id of the pet that will be used for testing
//   uint expectedPetId = 8;

//   //The expected owner of adopted pet is this contract
//   address expectedAdopter = address(this);

// //     // Testing the adopt() function
// // function testUserCanAdoptPet() public {
// //   uint returnedId = adoption.adopt(expectedPetId);

// //   Assert.equal(returnedId, expectedPetId, "Adoption of the expected pet should match what is returned.");
// // }
// // // Testing retrieval of a single pet's owner
// function testGetAdopterAddressByPetId() public {
//   address adopter = adoption.adopters(expectedPetId);

//   Assert.equal(adopter, expectedAdopter, "Owner of the expected pet should be this contract");
// }
// // Testing retrieval of all pet owners
// function testGetAdopterAddressByPetIdInArray() public {
//   // Store adopters in memory rather than contract's storage
//   address[16] memory adopters = adoption.getAdopters();

//   Assert.equal(adopters[expectedPetId], expectedAdopter, "Owner of the expected pet should be this contract");
// }


// }
