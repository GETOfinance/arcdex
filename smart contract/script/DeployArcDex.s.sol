pragma solidity =0.6.12;

import "../contracts/uniswapv2/UniswapV2Factory.sol";
import "../contracts/uniswapv2/UniswapV2Router02.sol";

interface Vm {
    function envUint(string calldata name) external returns (uint256 value);
    function envAddress(string calldata name) external returns (address value);
    function addr(uint256 privateKey) external returns (address keyAddr);
    function startBroadcast(uint256 privateKey) external;
    function stopBroadcast() external;
}

contract DeployArcDex {
    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    event ArcDexDeployed(address indexed factory, address indexed router, address indexed feeToSetter);

    function run() external returns (UniswapV2Factory factory, UniswapV2Router02 router) {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);
        address feeToSetter = vm.envAddress("FEE_TO_SETTER");
        require(feeToSetter != address(0), "Deploy: ZERO_FEE_SETTER");

        vm.startBroadcast(privateKey);
        factory = new UniswapV2Factory(feeToSetter);
        router = new UniswapV2Router02(address(factory));
        vm.stopBroadcast();

        emit ArcDexDeployed(address(factory), address(router), feeToSetter);
        require(deployer != address(0), "Deploy: INVALID_KEY");
    }
}

