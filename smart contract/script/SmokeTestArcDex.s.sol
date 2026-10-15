pragma solidity =0.6.12;

import "../contracts/uniswapv2/UniswapV2Factory.sol";
import "../contracts/uniswapv2/UniswapV2Router02.sol";
import "../contracts/uniswapv2/UniswapV2Pair.sol";
import "../contracts/uniswapv2/libraries/SafeMath.sol";

interface VmSmoke {
    function envUint(string calldata name) external returns (uint256 value);
    function envAddress(string calldata name) external returns (address value);
    function addr(uint256 privateKey) external returns (address keyAddr);
    function startBroadcast(uint256 privateKey) external;
    function stopBroadcast() external;
}

interface IERC20ArcSmoke {
    function balanceOf(address owner) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract ArcSmokeToken {
    using SafeMathUniswap for uint256;

    string public constant name = "ArcSwap Smoke Test Token";
    string public constant symbol = "GSTEST";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    function mint(address to, uint256 amount) external {
        balanceOf[to] = balanceOf[to].add(amount);
        totalSupply = totalSupply.add(amount);
        emit Transfer(address(0), to, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        if (allowance[from][msg.sender] != uint256(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(amount);
        }
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) private {
        balanceOf[from] = balanceOf[from].sub(amount);
        balanceOf[to] = balanceOf[to].add(amount);
        emit Transfer(from, to, amount);
    }
}

/// @notice Executes an Arc Mainnet add-liquidity, swap, and remove-liquidity smoke test.
contract SmokeTestArcDex {
    VmSmoke private constant vm = VmSmoke(address(uint160(uint256(keccak256("hevm cheat code")))));
    address private constant USDC = 0x3600000000000000000000000000000000000000;

    function run() external returns (ArcSmokeToken token, address pair) {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address account = vm.addr(privateKey);
        UniswapV2Factory factory = UniswapV2Factory(vm.envAddress("FACTORY_ADDRESS"));
        UniswapV2Router02 router = UniswapV2Router02(vm.envAddress("ROUTER_ADDRESS"));

        require(router.factory() == address(factory), "Smoke: FACTORY_MISMATCH");

        vm.startBroadcast(privateKey);
        token = new ArcSmokeToken();
        token.mint(account, 10 ether);
        require(IERC20ArcSmoke(USDC).approve(address(router), uint256(-1)), "Smoke: USDC_APPROVE_FAILED");
        require(token.approve(address(router), uint256(-1)), "Smoke: TOKEN_APPROVE_FAILED");

        (,, uint256 liquidity) = router.addLiquidity(
            USDC, address(token), 1_000_000, 1 ether, 1_000_000, 1 ether, account, block.timestamp + 1 hours
        );
        pair = factory.getPair(USDC, address(token));
        require(pair != address(0) && liquidity > 0, "Smoke: ADD_LIQUIDITY_FAILED");

        address[] memory path = new address[](2);
        path[0] = USDC;
        path[1] = address(token);
        uint256 tokenBalanceBefore = token.balanceOf(account);
        router.swapExactTokensForTokens(10_000, 1, path, account, block.timestamp + 1 hours);
        require(token.balanceOf(account) > tokenBalanceBefore, "Smoke: SWAP_FAILED");

        require(UniswapV2Pair(pair).approve(address(router), liquidity), "Smoke: LP_APPROVE_FAILED");
        (uint256 usdcOut, uint256 tokenOut) =
            router.removeLiquidity(USDC, address(token), liquidity, 1, 1, account, block.timestamp + 1 hours);
        require(usdcOut > 0 && tokenOut > 0, "Smoke: REMOVE_LIQUIDITY_FAILED");
        vm.stopBroadcast();
    }
}
