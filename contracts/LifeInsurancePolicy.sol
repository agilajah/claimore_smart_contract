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

    event Insured(string insuredName, uint insurancePrice);
    event Claimed(uint payout); 
    event DividendsPayed(uint date, uint payout); 

    struct DividendLine{
        uint amount;
        uint32 transferDate;
    }

    struct PolicyData {
        InsuredData insured;
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
        string insuredAge;
        bool insuredSmokingStatus;
        string insuredGender;
        string insuredOccupation;
        string insuredRegion;
        string insuredNIK;
        string insuredDeathLetterNumber;
        string insuredGovernmentLetterNumber;
        string insuredDeathHospital;
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

        // Insured Gender
        insuranceParameters['insuredGender']['male'] = 110;
        insuranceParameters['insuredGender']['female'] = 120;

        // Insured Occupation
        insuranceParameters['insuredOccupation']['pilot'] = 125;
        insuranceParameters['insuredOccupation']['army'] = 125;
        insuranceParameters['insuredOccupation']['police'] = 125;
        insuranceParameters['insuredOccupation']['pilot'] = 125;
        insuranceParameters['insuredOccupation']['driver'] = 115;
        insuranceParameters['insuredOccupation']['default'] = 110;
        

        // Insured Region
        insuranceParameters['insuredRegion']['java'] = 100;
        insuranceParameters['insuredRegion']['sumatra'] = 110;
        insuranceParameters['insuredRegion']['default'] = 115;

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
    function policyPrice(string insuredAge, string insuredSmokingStatus, string insuredGender, string insuredOccupation, string insuredRegion) constant returns(uint price) {
        // set defaults
        uint insuredAgeMultiplier = insuranceParameters['insuredAge']['default'];
        uint insuredSmokingStatusMultiplier = insuranceParameters['insuredSmokingStatus']['no'];
        uint insuredGenderMultiplier = insuranceParameters['insuredGender']['male'];
        uint insuredOccupationMultiplier = insuranceParameters['insuredOccupation']['default'];
        uint insuredRegionMultiplier = insuranceParameters['insuredRegion']['default'];

        if(insuranceParameters['insuredAge'][insuredAge] != 0) {
            insuredAgeMultiplier = insuranceParameters['insuredAge'][insuredAge];
        }
        if(insuranceParameters['insuredSmokingStatus'][insuredSmokingStatus] != 'no') {
            insuredSmokingStatusMultiplier = insuranceParameters['insuredSmokingStatus'][insuredSmokingStatus];
        }
        if(insuranceParameters['insuredGender'][insuredGender] != 'male') {
            insuredGenderMultiplier = insuranceParameters['insuredGender']['female'];
        }
        if(insuranceParameters['insuredOccupation'][insuredOccupation] != 0) {
            insuredOccupationMultiplier = insuranceParameters['insuredOccupation'][insuredOccupation];
        }
        if(insuranceParameters['insuredRegion'][insuredRegion] != 0) {
            insuredRegionMultiplier = insuranceParameters['insuredRegion'][insuredRegion];
        }

        // / 100 is due to Solidity not supporting doubles
        uint riskPremium = basePremium * insuredAgeMultiplier / 100 * insuredSmokingStatusMultiplier / 100 
                            * insuredGenderMultiplier / 100 * insuredOccupationMultiplier / 100 * insuredRegionMultiplier / 100;

        uint officePremium = riskPremium / (100 - loading) * 100; 
        return officePremium;
    }

    function insure(string userId, string insuredName, string insuredAge, bool insuredSmokingStatus, string insuredGender, string insuredOccupation, string insuredRegion, string insuredNIK, string insuredDeathLetterNumber, string insuredGovernmentLetterNumber, string insuredDeathHospital, string policyNumber) payable returns (bool insured) {
        require(totalInsurers < policiesLimit);
    
        uint totalPrice = policyPrice(insuredAge, insuredSmokingStatus, insuredGender, insuredOccupation, insuredRegion);
        uint monthlyPayment = totalPrice / 12;
        
        writtenPremiumAmount += totalPrice; 
    
        require(msg.value >= monthlyPayment);
    
        var insuredData = InsuredData(userId, insuredName, insuredAge, insuredSmokingStatus, insuredGender, insuredOccupation, insuredRegion, insuredNIK, insuredDeathLetterNumber, insuredGovernmentLetterNumber, insuredDeathHospital, policyNumber);
        var policy = PolicyData(insuredData, now + 1 years, now + 30 days, monthlyPayment, maxPayout, totalPrice, region, false, false);
    
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
        var userPolicy = insurancePolicies[msg.sender];
        var userData = userPolicy.insuredData;
    
        if(userData.insuredNIK == insuredNIK && userData.insuredDeathLetterNumber == insuredDeathLetterNumber 
            && userData.insuredGovernmentLetterNumber == insuredGovernmentLetterNumber && userData.insuredDeathHospital == insuredDeathHospital && userData.policyNumber == policyNumber && userPolicy.endDateTimestamp != 0 && !userPolicy.claimed && userPolicy.endDateTimestamp > now && userPolicy.confirmed) {
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

}