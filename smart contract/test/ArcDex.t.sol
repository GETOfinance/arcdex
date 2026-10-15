pragma solidity =0.6.12;

import "../contracts/uniswapv2/UniswapV2Factory.sol";
import "../contracts/uniswapv2/UniswapV2Router02.sol";
import "../contracts/uniswapv2/UniswapV2Pair.sol";
import "../contracts/uniswapv2/libraries/SafeMath.sol";

interface VmTest {
    function chainId(uint256 newChainId) external;
    function expectRevert(bytes calldata revertData) external;
    function etch(address target, bytes calldata newRuntimeBytecode) external;
    function deal(address account, uint256 newBalance) external;
}

contract MockUSDC {
    using SafeMathUniswap for uint256;

    string public constant name = "USD Coin";
    string public constant symbol = "USDC";
    uint8 public constant decimals = 6;
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

    function _transfer(address from, address to, uint256 amount) internal virtual {
        balanceOf[from] = balanceOf[from].sub(amount);
        balanceOf[to] = balanceOf[to].add(amount);
        emit Transfer(from, to, amount);
    }
}

contract MockToken is MockUSDC {
    string public constant tokenName = "Test Token";
    string public constant tokenSymbol = "TEST";
}

contract FeeToken is MockUSDC {
    address public constant FEE_SINK = address(0xFEE);

    function _transfer(address from, address to, uint256 amount) internal override {
        uint256 fee = amount / 100;
        uint256 received = amount.sub(fee);
        balanceOf[from] = balanceOf[from].sub(amount);
        balanceOf[to] = balanceOf[to].add(received);
        balanceOf[FEE_SINK] = balanceOf[FEE_SINK].add(fee);
        emit Transfer(from, to, received);
        emit Transfer(from, FEE_SINK, fee);
    }
}

contract ArcDexTest {
    using SafeMathUniswap for uint256;

    VmTest private constant vm = VmTest(address(uint160(uint256(keccak256("hevm cheat code")))));
    address private constant USDC = 0x3600000000000000000000000000000000000000;

    UniswapV2Factory private factory;
    UniswapV2Router02 private router;
    MockToken private token;

    function setUp() public {
        vm.chainId(5042);
        vm.etch(USDC, type(MockUSDC).runtimeCode);
        factory = new UniswapV2Factory(address(this));
        router = new UniswapV2Router02(address(factory));
        token = new MockToken();
        MockUSDC(USDC).mint(address(this), 10_000_000e6);
        token.mint(address(this), 10_000_000e6);
        MockUSDC(USDC).approve(address(router), uint256(-1));
        token.approve(address(router), uint256(-1));
    }

    function testArcConfiguration() public view {
        _assertEq(factory.ARC_CHAIN_ID(), 5042, "factory chain");
        _assertEq(router.ARC_CHAIN_ID(), 5042, "router chain");
        _assertEq(factory.USDC(), USDC, "factory USDC");
        _assertEq(router.USDC(), USDC, "router USDC");
    }

    function testRejectsDeploymentOnAnotherChain() public {
        vm.chainId(1);
        vm.expectRevert(bytes("ArcDEX: WRONG_CHAIN"));
        new UniswapV2Factory(address(this));
    }

    function testFactoryOnlyCreatesUSDCPairs() public {
        MockToken other = new MockToken();
        vm.expectRevert(bytes("ArcDEX: USDC_PAIR_REQUIRED"));
        factory.createPair(address(token), address(other));
    }

    function testCreate2AddressMatchesFactory() public {
        address expected = _pairFor(address(factory), USDC, address(token), factory.pairCodeHash());
        address actual = factory.createPair(USDC, address(token));
        _assertEq(actual, expected, "CREATE2 pair");
    }

    function testAddSwapAndRemoveLiquidity() public {
        (,, uint256 liquidity) =
            router.addLiquidity(USDC, address(token), 1_000_000e6, 1_000_000e6, 0, 0, address(this), block.timestamp);
        address pairAddress = factory.getPair(USDC, address(token));
        require(liquidity > 0, "no liquidity");

        address[] memory path = new address[](2);
        path[0] = USDC;
        path[1] = address(token);
        uint256 beforeSwap = token.balanceOf(address(this));
        router.swapExactTokensForTokens(10_000e6, 1, path, address(this), block.timestamp);
        require(token.balanceOf(address(this)) > beforeSwap, "swap failed");

        UniswapV2Pair pair = UniswapV2Pair(pairAddress);
        pair.approve(address(router), liquidity);
        (uint256 usdcOut, uint256 tokenOut) =
            router.removeLiquidity(USDC, address(token), liquidity, 1, 1, address(this), block.timestamp);
        require(usdcOut > 0 && tokenOut > 0, "remove failed");
    }

    function testFeeOnTransferExactInputSwap() public {
        FeeToken feeToken = new FeeToken();
        feeToken.mint(address(this), 2_000_000e6);
        feeToken.approve(address(router), uint256(-1));
        router.addLiquidity(USDC, address(feeToken), 1_000_000e6, 1_000_000e6, 0, 0, address(this), block.timestamp);

        address[] memory path = new address[](2);
        path[0] = address(feeToken);
        path[1] = USDC;
        uint256 beforeSwap = MockUSDC(USDC).balanceOf(address(this));
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(10_000e6, 1, path, address(this), block.timestamp);
        require(MockUSDC(USDC).balanceOf(address(this)) > beforeSwap, "fee swap failed");
    }

    function testFlashSwapRepaysWithFee() public {
        router.addLiquidity(USDC, address(token), 1_000_000e6, 1_000_000e6, 0, 0, address(this), block.timestamp);
        UniswapV2Pair pair = UniswapV2Pair(factory.getPair(USDC, address(token)));
        uint256 amountOut = 10_000e6;
        uint256 reserveBefore = MockUSDC(USDC).balanceOf(address(pair));

        if (pair.token0() == USDC) {
            pair.swap(amountOut, 0, address(this), hex"01");
        } else {
            pair.swap(0, amountOut, address(this), hex"01");
        }

        require(MockUSDC(USDC).balanceOf(address(pair)) > reserveBefore, "flash fee missing");
    }

    function testProtocolFeeMintsLiquidity() public {
        address feeRecipient = address(0xBEEF);
        factory.setFeeTo(feeRecipient);
        router.addLiquidity(USDC, address(token), 1_000_000e6, 1_000_000e6, 0, 0, address(this), block.timestamp);

        address[] memory path = new address[](2);
        path[0] = USDC;
        path[1] = address(token);
        router.swapExactTokensForTokens(100_000e6, 1, path, address(this), block.timestamp);
        router.addLiquidity(USDC, address(token), 10_000e6, 10_000e6, 0, 0, address(this), block.timestamp);

        UniswapV2Pair pair = UniswapV2Pair(factory.getPair(USDC, address(token)));
        require(pair.balanceOf(feeRecipient) > 0, "protocol fee missing");
    }

    function testRouterRejectsNativeValue() public {
        vm.deal(address(this), 1 ether);
        (bool success,) = address(router).call{value: 1}("");
        require(!success, "native value accepted");
    }

    function uniswapV2Call(address, uint256 amount0, uint256 amount1, bytes calldata) external {
        UniswapV2Pair pair = UniswapV2Pair(msg.sender);
        uint256 borrowed = amount0 > 0 ? amount0 : amount1;
        address borrowedToken = amount0 > 0 ? pair.token0() : pair.token1();
        uint256 repayment = (borrowed.mul(1000) / 997).add(1);
        require(MockUSDC(borrowedToken).transfer(msg.sender, repayment), "flash repay failed");
    }

    function _pairFor(address factoryAddress, address tokenA, address tokenB, bytes32 codeHash)
        private
        pure
        returns (address pair)
    {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(hex"ff", factoryAddress, keccak256(abi.encodePacked(token0, token1)), codeHash)
                    )
                )
            )
        );
    }

    function _assertEq(uint256 actual, uint256 expected, string memory message) private pure {
        require(actual == expected, message);
    }

    function _assertEq(address actual, address expected, string memory message) private pure {
        require(actual == expected, message);
    }
}
