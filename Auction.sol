pragma solidity ^0.4.2;

contract Auction {
    struct Bidder {
        address biddeAddress;
        int[2] w;
        int[2][] need;
    }
    
    struct Notary {
        address notaryAddress;
        int[2] w;
        int[2][] need;
        int transactions;
    }
    
    address[] public notaryAccs;
    address[] public notaryAccsCopy;
    address[] public bidderAccs;
    address[] public winnerAccs;
    
    address owner;
    
    enum AuctionStatus {Pending, Active, Inactive}
    
    AuctionStatus a;
    
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }
    
    modifier onlyAfterAuctionCreated () {
        require(a == AuctionStatus.Active, "Auction not started");
        _;
    }
    
    constructor () public {
        owner = msg.sender;
        a =AuctionStatus.Inactive;
    }
    
    struct AuctionItems {
        int q;
        int[] items;
    }
    
    AuctionItems public aux;
    
    mapping(address => Notary) Notries;
    
    mapping(address => Bidder) Bidders;
    
    mapping(address => address) bidderNotaryAssignment;
    
    function createAuction (int q, int[] items) onlyOwner public {
        aux.q = q;
        aux.items = items;
        a = AuctionStatus.Active;
    }
    
    // function getAucItems () public returns (int[] items) {
    //     return aux.items;
    // }
    
    function registerNotary () public onlyAfterAuctionCreated returns(address) {
        Notary storage aNotary = Notries[msg.sender];
        
        aNotary.notaryAddress = msg.sender;
        
        notaryAccs.push(msg.sender);
        notaryAccsCopy.push(msg.sender);
        
        return aNotary.notaryAddress;
    }
    
    function registerBidder (int[2] w, int[2][] ItemPairs) public onlyAfterAuctionCreated returns(uint) {
        Bidder storage aBidder = Bidders[msg.sender];
        
        aBidder.biddeAddress = msg.sender;
        aBidder.w = w;
        aBidder.need = ItemPairs;
        
        uint ran = random();
        
        bidderNotaryAssignment[msg.sender] = notaryAccsCopy[ran];
        
        Notries[notaryAccsCopy[ran]].w = w;
        Notries[notaryAccsCopy[ran]].need = ItemPairs;
        
        // address temp = notaryAccsCopy[ran];
        notaryAccsCopy[ran] = notaryAccsCopy[notaryAccsCopy.length - 1];
        notaryAccsCopy[notaryAccsCopy.length - 1] = notaryAccsCopy[ran];
        
        delete notaryAccsCopy[notaryAccsCopy.length - 1];
        
        notaryAccsCopy.length--;
        
        return ran;
    }
    
    function getNotary (address i) public returns (int[2], int[2][], int, uint) {
        return (Notries[i].w, Notries[i].need, Notries[i].transactions, Notries[i].need.length);
    }
    
    uint nonce;

    function random() internal returns (uint) {
        uint randomNumber = uint(keccak256(now, msg.sender, nonce)) % notaryAccsCopy.length;
        nonce++;
        return randomNumber;
    }
    
    function getAssignedNotary () public returns(address) {
        return bidderNotaryAssignment[msg.sender];
    }
    
    function sort () public onlyOwner {
        uint notaryAccsLength = notaryAccs.length;
        for(uint i = 0; i < notaryAccsLength; i++) {
            for (uint j = i + 1; j < notaryAccsLength; j++) {
                if (compare(notaryAccs[i], notaryAccs[j])) {
                    address temp = notaryAccs[i];
                    notaryAccs[i] = notaryAccs[j];
                    notaryAccs[j] = temp;
                }
            }
        }
    }
    
    // mapping (address => int) message;
    
    // function sendMessage(address _recipient, int _message) internal {
    //     message[_recipient] = _message;
    // }
    
    // function readMessage() internal returns (int) {
    //     return message[msg.sender];
    // }

    // function sendFirst(address sendTo) internal {
    //     address myAddress = msg.sender;
    //     sendMessage(sendTo, Notries[myAddress].w[0]); 
    // }
    
    // function readFirst(address replyTo)  internal {
    //     address myAddress = msg.sender;
    //     int u_j = readMessage();
    //     int val1 = Notries[myAddress].w[0] - u_j;
    //     sendMessage(replyTo, val1);
    // }
    
    // function sendSecond (address sendTo) {
    //     address myAddress = msg.sender;
    //     sendMessage(sendTo, Notries[myAddress].w[1]); 
    // }
    
    // function readSecond (address replyTo)  {
    //     address myAddress = msg.sender;
    //     int v_i = readMessage();
    //     int val2 = v_i - Notries[myAddress].w[1];
    //     sendMessage(replyTo, val2);
    // }
    
    // function sendLength(address sendTo) {
    //     address myAddress = msg.sender;
    //     sendMessage(sendTo, int(Notries[myAddress].need.length)); 
    // }
    
    // function compare(address n_i, address n_j) internal onlyOwner returns (bool) {
    //     n_j.call(bytes4(keccak256("sendFirst(address)")), n_i);
    //     n_i.call(bytes4(keccak256("readFirst(address)")), msg.sender);
    //     int val1 = readMessage();
    //     n_i.call(bytes4(keccak256("sendSecond(address)")), n_j);
    //     n_j.call(bytes4(keccak256("readSecond(address)")), msg.sender);
    //     int val2 = readMessage();
        
    //     int sum = val1 + val2;
        
    //     if (sum < 0) {
    //         sum = sum + aux.q;
    //     } else {
    //         sum = sum % aux.q;
    //     }
        
    //     if (sum == 0) {
    //         return false;
    //         // < aux.q/2
    //     } else if (sum < aux.q/2) {
    //         return false;
    //     } else {
    //         return true;
    //     }
    // }
    
    function compare(address n_i, address n_j) internal onlyOwner returns (bool) {
        int val1 = Notries[n_i].w[0] - Notries[n_j].w[0];
        int val2 = Notries[n_i].w[1] - Notries[n_j].w[1];
        
        Notries[n_i].transactions++;
        Notries[n_j].transactions++;
        
        int sum = val1 + val2;
        
        if (sum < 0) {
            sum = sum + aux.q;
        } else {
            sum = sum % aux.q;
        }
        
        if (sum == 0) {
            return false;
            // < aux.q/2
        } else if (sum < aux.q/2) {
            return false;
        } else {
            return true;
        }
    }
    
    // function sendItemFirst(address sendTo, uint i) {
    //     address myAddress = msg.sender;
    //     sendMessage(sendTo, Notries[myAddress].need[0][i]); 
    // }
    
    // function readItemFirst(address replyTo, uint i)  {
    //     address myAddress = msg.sender;
    //     int u_j = readMessage();
    //     int val1 = Notries[myAddress].need[0][i] - u_j;
    //     sendMessage(replyTo, val1);
    // }
    
    // function sendItemSecond (address sendTo, uint i) {
    //     address myAddress = msg.sender;
    //     sendMessage(sendTo, Notries[myAddress].need[1][i]); 
    // }
    
    // function readItemSecond (address replyTo, uint i)  {
    //     address myAddress = msg.sender;
    //     int v_i = readMessage();
    //     int val2 = v_i - Notries[myAddress].need[1][i];
    //     sendMessage(replyTo, val2);
    // }
    
    // function compareItems(address n_i, address n_j) internal onlyOwner returns (bool) {
        
    //     n_i.call(keccak256("sendLength(address)"), msg.sender);
    //     uint i_length = uint(readMessage());
    //     n_j.call(keccak256("sendLength(address)"), msg.sender);
    //     uint j_length = uint(readMessage());
        
    //     for (uint i = 0; i < i_length; i++) {
    //         for (uint j = 0; j < j_length; j++) {
    //             n_i.call(bytes4(keccak256("sendItemFirst(address, uint)")), n_j, i);
    //             n_j.call(bytes4(keccak256("readItemFirst(address, uint)")), msg.sender, j);
    //             int val1 = readMessage();
    //             n_j.call(bytes4(keccak256("sendItemSecond(address, uint)")), n_i, j);
    //             n_i.call(bytes4(keccak256("readItemSecond(address, uint)")), msg.sender, i);
    //             int val2 = readMessage();
    //             if (val1 + val2 == 0) {
    //                 return true;
    //                 // < aux.q/2
    //             }
    //         }
    //     }
    // }
    
    function compareItems(address n_i, address n_j) public onlyOwner returns (bool, int[], int[]) {
        
        // n_i.call(keccak256("sendLength(address)"), msg.sender);
        // uint i_length = uint(readMessage());
        // n_j.call(keccak256("sendLength(address)"), msg.sender);s
        // uint j_length = uint(readMessage());
        // uint len = notaryAccs.length;
        
        int[] ret;
        int[] i_needs;
        // int[] j_needs;
        
        for (uint i = 0; i < Notries[n_i].need.length; i++) {
            for (uint j = 0; j < Notries[n_j].need.length; j++) {
                // n_i.call(bytes4(keccak256("sendItemFirst(address, uint)")), n_j, i);
                // n_j.call(bytes4(keccak256("readItemFirst(address, uint)")), msg.sender, j);
                // int val1 = readMessage();
                // n_j.call(bytes4(keccak256("sendItemSecond(address, uint)")), n_i, j);
                // n_i.call(bytes4(keccak256("readItemSecond(address, uint)")), msg.sender, i);
                // int val2 = readMessage();
                int a = Notries[n_i].need[0][i];
                int b = Notries[n_j].need[0][j];
                // int val1 = Notries[n_i].need[0][i] - Notries[n_j].need[0][j];
                // int val2 = Notries[n_i].need[1][i] - Notries[n_j].need[1][j];
                int val1 = a-b;
                a = Notries[n_i].need[1][i];
                b = Notries[n_j].need[1][j];
                int val2 = a-b;
                
                Notries[n_i].transactions++;
                Notries[n_j].transactions++;
                
                // i_needs.push(Notries[n_i].need[0][i]);
                // i_needs.push(Notries[n_j].need[0][j]);
                // i_needs.push(Notries[n_i].need[1][i]);
                // i_needs.push(Notries[n_j].need[1][j]);
                
                ret.push(val1);
                ret.push(val2);
                
                if (val1 + val2 == 0) {
                    return (true, ret, i_needs);
                    // < aux.q/2
                }
            }
        }
        
        return (false, ret, i_needs);
    }
    
    function getSortedValue() public returns (address[]) {
        return notaryAccs;
    }
    
    function getCopy() public returns (address[]) {
        return notaryAccsCopy;
    }
    
    function calculateWinners() public onlyOwner returns(int[]) {
        // int[2][] storage auctionedItems;
        bool isWinner = true;
        bool isComp;
        int[] memory a;
        int[] b;
        for (uint i = 0; i < notaryAccs.length; i++) {
            if (i == 0) {
                winnerAccs.push(notaryAccs[i]);
                // for (uint e = 0; e < Notries[notaryAccs[i]].need.length; e++)
                //     auctionedItems.push(Notries[notaryAccs[i]].need[e]);
            } else {
                // int[2][] needsOfBidderI = Notries[notaryAccs[i]].need;
                isWinner = true;
                for (uint j = 0; j < winnerAccs.length; j++) {
                    (isComp,a, a) = compareItems(winnerAccs[j], notaryAccs[i]);
                    int c;
                    for (uint l = 0; l < a.length; l++) {
                        c = a[l];
                        b.push(c);
                    }
                    if (isComp) {
                        isWinner = false;
                        break;
                    }
                }
                
                if (isWinner) {
                    winnerAccs.push(notaryAccs[i]);
                    // for (uint n = 0; n < Notries[notaryAccs[i]].need.length; n++)
                    //     auctionedItems.push(Notries[notaryAccs[i]].need[n]);
                }
            }
        }
        
        return b;
    }
    
    function getWinners() public returns (address[]) {
        return winnerAccs;
    }
    
}
