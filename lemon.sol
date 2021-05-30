pragma solidity >=0.4.24;

contract Lemon {
    address owner;

    uint256 skuCount;

    enum State {ForSale, Sold, Shipped}

    struct Item {
        string name;
        uint256 sku;
        uint256 price;
        State state;
        address seller;
        address buyer;
    }

    mapping(uint256 => Item) items;

    event ForSale(uint256 skuCount);

    event Sold(uint256 sku);

    event Shipped(uint256 sku);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier verifyCaller(address _address) {
        require(msg.sender == _address);
        _;
    }

    modifier paidEnough(uint256 _price) {
        require(msg.value >= _price);
        _;
    }

    modifier forSale(uint256 _sku) {
        require(items[_sku].state == State.ForSale);
        _;
    }

    modifier sold(uint256 _sku) {
        require(items[_sku].state == State.Sold);
        _;
    }

    modifier shipped(uint256 _sku) {
        require(items[_sku].state == State.Shipped);
        _;
    }

    modifier checkValue(uint256 _sku) {
        uint256 _price = items[_sku].price;
        uint256 amountToRefund = msg.value - _price;
        payable(address(items[_sku].buyer)).transfer(amountToRefund);
        _;
    }

    constructor() public {
        owner = msg.sender;
        skuCount = 0;
    }

    function addItem(string memory _name, uint256 _price) public onlyOwner {
        skuCount = skuCount + 1;

        emit ForSale(skuCount);

        items[skuCount] = Item({
            name: _name,
            sku: skuCount,
            price: _price,
            state: State.ForSale,
            seller: address(msg.sender),
            buyer: address(0)
        });
    }

    function buyItem(uint256 _sku)
        public
        payable
        forSale(_sku)
        paidEnough(items[_sku].price)
        checkValue(_sku)
    {
        address payable buyer = payable(address(msg.sender));
        uint256 price = items[_sku].price;

        items[_sku].buyer = buyer;

        items[_sku].state = State.Sold;

        payable(address(items[_sku].seller)).transfer(price);

        emit Sold(_sku);
    }

    function fetchItem(uint256 _sku)
        public
        view
        returns (
            string memory name,
            uint256 sku,
            uint256 price,
            string memory stateIs,
            address seller,
            address buyer
        )
    {
        uint256 state;
        name = items[_sku].name;
        sku = items[_sku].sku;
        price = items[_sku].price;
        state = uint256(items[_sku].state);

        if (state == 0) {
            stateIs = "For Sale";
        } else if (state == 1) {
            stateIs = "Sold";
        } else if (state == 2) {
            stateIs = "Shipped";
        }

        seller = items[_sku].seller;
        buyer = items[_sku].buyer;
    }

    function shipItem(uint256 _sku)
        public
        sold(_sku)
        verifyCaller(items[_sku].seller)
    {
        items[_sku].state = State.Shipped;
        emit Shipped(_sku);
    }
}
