pragma solidity ^0.4.17;


//import "./PolicyInvestable.sol";
contract PolicyInvestable {
  function invest() payable returns (bool success);

  event Invested(uint value);
}


//import "./SafeMath.sol";

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract LifeInsurancePolicy is PolicyInvestable { 
    using SafeMath for uint256;
    // Investment data 
    mapping (address => uint) public investors;
    uint public totalInvestorsCount;
    uint public totalInvestedAmount;

    uint public totalInsurers;
    uint public totalClaimsPaid;
    
    uint128 public investmentsLimit;
    uint32 public investmentsDeadlineTimeStamp;
    
    uint8 constant DECIMAL_PRECISION = 8;
    uint24 constant ALLOWED_RETURN_INTERVAL_SEC = 24 * 60 * 60; // each 24 hours

    mapping (address => DividendLine[]) private payedDividends;
    uint public payedDividendsAmount;

    // Insurance data
    uint public policiesLimit;
    mapping (address => PolicyData) insurancePolicies;
    mapping (string => mapping(string => uint) ) insuranceParameters;
    uint public basePremium;
    uint public maxPayout;
    uint loading;
    uint public writtenPremiumAmount;
    uint32 public lastPolicyDate;

    event Insured(string deviceName, uint insurancePrice);
    event Claimed(uint payout); 
    event DividendsPayed(uint date, uint payout); 

    struct DividendLine{
        uint amount;
        uint32 transferDate;
    }

    struct PolicyData {
        DeviceData device;
        uint endDateTimestamp;
        uint nextPaymentTimestamp;
        uint monthlyPayment;
        uint maxPayout;
        uint totalPrice;
        string region;
        bool claimed;
        bool confirmed;
    }

    struct InsuredData {
        string userId;
        string insuredName;
        string insuredAge,
        bool insuredSmokingStatus,
        string insuredGender,
        string insuredHeight,
        string insuredWeight,
    }

    function LifeInsurancePolicy() payable {
        // Initial funds
        investors[msg.sender] = investors[msg.sender] + msg.value;
        totalInvestorsCount++;
        totalInvestedAmount = totalInvestedAmount + msg.value;
        Invested(msg.value);

        setInitialInsuranceParameters();
    }

    function setInitialInsuranceParameters() internal {
        string insuredAge,
        string insuredSmokingStatus,
        string insuredGender,
        string insuredOccupation;
        string insuredLocation;

        // Insured Age upper than
        insuranceParameters['age']['10'] = 70;
        insuranceParameters['age']['15'] = 80;
        insuranceParameters['age']['20'] = 90;
        insuranceParameters['age']['25'] = 100;
        insuranceParameters['age']['30'] = 110;
        insuranceParameters['age']['35'] = 120;

        // Insured smoking status
        insuranceParameters['insuredSmokingStatus']['yes'] = 120;
        insuranceParameters['insuredSmokingStatus']['no'] = 100;

        // Insured Gender
        insuranceParameters['insuredGender']['male'] = 110;
        insuranceParameters['insuredGender']['female'] = 120;

        // Insured Occupation
        insuranceParameters['insuredOccupation']['pilot'] = 125;
        insuranceParameters['insuredOccupation']['army'] = 125;
        insuranceParameters['insuredOccupation']['police'] = 125;
        insuranceParameters['insuredOccupation']['pilot'] = 125;
        insuranceParameters['insuredOccupation']['driver'] = 115;
        insuranceParameters['insuredOccupation']['entrepreneur'] = 110;
        

        // Insured location
        insuranceParameters['insuredLocation']['java'] = 100;
        insuranceParameters['insuredLocation']['sumatra'] = 110;
        insuranceParameters['insuredLocation']['kalimantan'] = 120;
        insuranceParameters['insuredLocation']['irian'] = 130;

        // Base premium (0.001 ETH)
        basePremium = 1000000000000000;

        // Max payout (0.01 ETH)
        maxPayout = 10000000000000000;
        
        investmentsLimit = 1000000000000000000000; //1000 ETH
        investmentsDeadlineTimeStamp = uint32(now) + 90 days;
        lastPolicyDate = uint32(now) + 90 days;
        policiesLimit = 10000;

        // Loading percentage (expenses, etc)
        loading = 50;
    }



}