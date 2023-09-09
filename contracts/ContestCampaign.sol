// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

contract ContestCampaign is VRFConsumerBaseV2, ConfirmedOwner {

    /////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////// R a n d o m G e n ///////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
    bytes32 keyHash =
        0x6e099d640cde6de9d40ac749b4b594126b0169747122711109c9985d47751f93;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 200000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 1;

    constructor(uint64 subscriptionId)
        VRFConsumerBaseV2(0xAE975071Be8F8eE67addBC1A82488F1C24858067)
        ConfirmedOwner(msg.sender)
    {
        COORDINATOR = VRFCoordinatorV2Interface(
            0xAE975071Be8F8eE67addBC1A82488F1C24858067
        );
        s_subscriptionId = subscriptionId;
    }

    ///////////////////////////////////
    //////// R a n d o m G e n ////////
    ///////////////////////////////////

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords()
        external
        onlyOwner
        returns (uint256 requestId)
    {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }
    
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override 
    {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
    }

    function getRequestStatus(uint256 requestID)
        public
        view
        returns (bool fulfilled, uint256[] memory randomWords)
    {
        require(s_requests[requestID].exists, "request not found");
        RequestStatus memory request = s_requests[requestID];
        return (request.fulfilled, request.randomWords);
    }

    function expand(uint256 n, uint256 range) public view onlyOwner returns (uint256[] memory expandedValues) {
        require(lastRequestId > 0, "random words not requested");
        require(n < range, "random size must be less than range");

        uint256[] memory randomValues = new uint[](1);
        (, randomValues) = getRequestStatus(lastRequestId);
        
        expandedValues = new uint[](n);
        
        uint256 ignoreCount = 0;
        for (uint256 i = 0; i < n; i++) {
            uint256 tempRand = uint256(keccak256(abi.encode(randomValues[0], i))) % range;
            if(isIn(expandedValues, tempRand)) {
                n += 1;
                ignoreCount += 1;
            } else {
                expandedValues[i - ignoreCount] = tempRand;
            } 
            // expandedValues[i] = randomValues[i] % (range - i);
        }
        
        return expandedValues;
    }

    function isIn(uint256[] memory arr, uint256 searchFor) internal pure returns (bool) {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == searchFor) {
                return true;
            }
        }
        return false; // not found
    }
}