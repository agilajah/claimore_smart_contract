pragma solidity ^0.4.17;


// import "./PolicyInvestable.sol";
contract PolicyInvestable {
    function invest() payable returns (bool success);
  
    event Invested(uint value);
}
// import "./SafeMath.sol";
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

// import "./stringUtils.sol";
import { StringUtils } from "./StringUtils.sol";

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


    // Insurance data
    uint public policiesLimit;
    mapping (address => PolicyData) insurancePolicies;
    mapping (string => mapping(string => uint) ) insuranceParameters;
    uint public basePremium;
    uint public maxPayout;
    uint loading;
    uint public writtenPremiumAmount;
    uint32 public lastPolicyDate;
    uint public monthlyPayment;
    uint public totalPrice;

    
    // Owner is used to confirm policies and claims which came via our server
    address owner = 0x627306090abaB3A6e1400e9345bC60c78a8BEf57;

    event Insured(string insuredName, uint insurancePrice);
    event Claimed(uint payout); 

    struct PolicyData {
        InsuredData insured;
        uint endDateTimestamp;
        uint nextPaymentTimestamp;
        uint monthlyPayment;
        uint maxPayout;
        uint totalPrice;
        bool claimed;
        bool confirmed;
    }

    struct InsuredDeathData {
        string insuredDeathLetterNumber;
        string insuredGovernmentLetterNumber;
        string insuredDeathHospital;
    }

    struct InsuredData {
        InsuredDeathData deathData;
        string userId;
        string insuredName;
        string insuredAge;
        string insuredSmokingStatus;
        string insuredOccupation;
        string insuredNIK;
        string policyNumber;
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
        // Insured Age upper than
        insuranceParameters['insuredAge']['10'] = 70;
        insuranceParameters['insuredAge']['15'] = 80;
        insuranceParameters['insuredAge']['20'] = 90;
        insuranceParameters['insuredAge']['25'] = 100;
        insuranceParameters['insuredAge']['30'] = 110;
        insuranceParameters['insuredAge']['default'] = 120;

        // Insured smoking status
        insuranceParameters['insuredSmokingStatus']['yes'] = 120;
        insuranceParameters['insuredSmokingStatus']['no'] = 100;


        // Insured Occupation
        insuranceParameters['insuredOccupation']['pilot'] = 125;
        insuranceParameters['insuredOccupation']['army'] = 125;
        insuranceParameters['insuredOccupation']['police'] = 125;
        insuranceParameters['insuredOccupation']['pilot'] = 125;
        insuranceParameters['insuredOccupation']['driver'] = 115;
        insuranceParameters['insuredOccupation']['default'] = 110;
        

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

    // fallback functon not to take ethers
    function() payable { 
        throw;
    }

    // policy part
    // More parameters should be included
    function policyPrice(string insuredAge, string insuredSmokingStatus,  string insuredOccupation) constant returns(uint price) {
        // set defaults
        uint insuredAgeMultiplier = insuranceParameters['insuredAge']['default'];
        uint insuredSmokingStatusMultiplier = insuranceParameters['insuredSmokingStatus'][insuredSmokingStatus];
        uint insuredOccupationMultiplier = insuranceParameters['insuredOccupation']['default'];

        if(insuranceParameters['insuredAge'][insuredAge] != 0) {
            insuredAgeMultiplier = insuranceParameters['insuredAge'][insuredAge];
        }
        if(insuranceParameters['insuredOccupation'][insuredOccupation] != 0) {
            insuredOccupationMultiplier = insuranceParameters['insuredOccupation'][insuredOccupation];
        }

        // / 100 is due to Solidity not supporting doubles
        uint riskPremium = basePremium * insuredAgeMultiplier / 100 * insuredSmokingStatusMultiplier / 100 
                         * insuredOccupationMultiplier / 100;

        uint officePremium = riskPremium / (100 - loading) * 100; 
        return officePremium;
    }
    function insure(string userId, string insuredName, string insuredAge, string insuredSmokingStatus, string insuredOccupation, string insuredNIK, string insuredDeathLetterNumber, string insuredGovernmentLetterNumber, string insuredDeathHospital, string policyNumber) payable returns (bool insured) {
        require(totalInsurers < policiesLimit);
    
        totalPrice = policyPrice(insuredAge, insuredSmokingStatus, insuredOccupation);
        monthlyPayment = totalPrice / 12;
        
        writtenPremiumAmount += totalPrice; 
    
        require(msg.value >= monthlyPayment);
    
        var deathData = InsuredDeathData(insuredDeathLetterNumber, insuredGovernmentLetterNumber, insuredDeathHospital);
        var insuredData = InsuredData(deathData, userId, insuredName, insuredAge, insuredSmokingStatus, insuredOccupation, insuredNIK, policyNumber);
        var policy = PolicyData(insuredData, now + 1 years, now + 30 days, monthlyPayment, maxPayout, totalPrice, false, false);
    
        insurancePolicies[msg.sender] = policy;
        totalInsurers = totalInsurers + 1;
        lastPolicyDate = uint32(policy.endDateTimestamp);
    
        Insured(insuredName, msg.value);
        return true;
    }

    function confirmPolicy(address policyOwner) {
        require(owner == msg.sender);
        insurancePolicies[policyOwner].confirmed = true;
    }

    function claim(string insuredNIK, string insuredDeathLetterNumber, string insuredGovernmentLetterNumber, string insuredDeathHospital, string policyNumber) returns (bool) {
        var userPolicy = insurancePolicies[owner];
        var userData = userPolicy.insured;
        var deathData = userPolicy.insured.deathData;
        var iNIK = insuredNIK;
        var iDeathLetterNumber = insuredDeathLetterNumber;
        var iGovernmentLetterNumber = insuredGovernmentLetterNumber;
        var iDeathHospital = insuredDeathHospital;
        var pNumber = policyNumber;
    
        if(StringUtils.equal(userData.insuredNIK, iNIK) && StringUtils.equal(deathData.insuredDeathLetterNumber, iDeathLetterNumber) && StringUtils.equal(deathData.insuredGovernmentLetterNumber, iGovernmentLetterNumber) && StringUtils.equal(deathData.insuredDeathHospital, iDeathHospital) && StringUtils.equal(userData.policyNumber, pNumber)  && userPolicy.endDateTimestamp != 0 && !userPolicy.claimed && userPolicy.endDateTimestamp > now && userPolicy.confirmed) {
            if(this.balance > userPolicy.maxPayout) {
                userPolicy.claimed = true;
                userPolicy.endDateTimestamp = now;
                userPolicy.nextPaymentTimestamp = 0;
        
                totalClaimsPaid = totalClaimsPaid + userPolicy.maxPayout;
                msg.sender.transfer(userPolicy.maxPayout);
                Claimed(userPolicy.maxPayout);
                return true;
            }
          // Due to proposed statisticl model in production app this should never happen
          return false;
        } else {
          throw;
        }
    }

    function getPolicyEndDateTimestamp() constant returns (uint) {
        return insurancePolicies[msg.sender].endDateTimestamp;
    }
    
    function getPolicyNextPayment() constant returns (uint) {
        return insurancePolicies[msg.sender].nextPaymentTimestamp;
    }
    
    function claimed() constant returns (bool) {
        return insurancePolicies[msg.sender].claimed;
    }

    //investor Part
    function invest() payable returns (bool success) {
        require(msg.value > 0);
        require(isInvestmentPeriodEnded() == false);

        investors[msg.sender] = investors[msg.sender] + msg.value;
        totalInvestorsCount++;
        totalInvestedAmount = totalInvestedAmount + msg.value;
        Invested(msg.value);
        return true;
    }

    function isInvestmentPeriodEnded() constant returns (bool) {
        return (investmentsDeadlineTimeStamp < now);
    }
}