/* Assumptions: 
    * Registered users are the users who have just registered themselves
    * Active users are the users who have sent at least one message
    * If a message was flagged  greater than the number of active users
        ** It'll be deleted if non-anonymous
        ** The indenty will be revealed if anonymous
    * To view all messages, you need to check the logs after executing logAllMessages()
    * since events are being used to print all messages. 
*/

pragma solidity ^0.4.0;
pragma experimental ABIEncoderV2;

contract SendMessage {
    string constant REDACTED = "REDACTED";
    uint constant MAX_USERS = 1000;
    uint constant MAX_MESSAGES = 1000;
    struct Message {
        string author; 
        string text;
        uint flags;
        bool isAnonymous; 
        bool isDeleted; 
    }
    
    struct User {
        string userName;
        mapping (uint => bool) flaggedMessages;
        bool isValid; 
    }
    
    Message[1000] messageList; 
    mapping (string => User)  userList; // userName to User mapping
    mapping (string => bool)  activeUsersList; // users who have send at least one message
    uint numActiveUsers;
    uint numMessages;
    
    
    constructor() public {
        numActiveUsers = 0;
        numMessages = 0;
    }

    event ValidMessage(string message);
    
    // The following function registers the user, 
    // without which they are not allowed to send a message. 
    function registerUser(string userName) public {
        require(!userList[userName].isValid, "User already exists!");
        userList[userName] = User(userName ,true);
    }
    
    // Sets the message for a particular user: 
    function setMessage(string userName, string text, bool isAnonymous) public payable {
        // if the user is unregistered, send an error
        require(userList[userName].isValid, "Sender not recognized."); 
        bool anonymity = false;
        
    
        // If the user wants msg to be anon, 
        // they must have paid 1 or more ether: 
        if(isAnonymous) {
            require(msg.value >= 0.1 ether, "Pay 0.1 or more ether to pay.");
            anonymity = true;
        } else {
            anonymity = false;
        }
        
        if (activeUsersList[userName] != true) {
            activeUsersList[userName] = true;
            numActiveUsers++;
        }
        messageList[numMessages] = Message(userName, text, 0, anonymity, false);
        numMessages++;
    }
    
    function flagMessage(string flaggerName,  uint msgID) public {
         // if the flagger or sender is unregistered, send an error
        require(userList[flaggerName].isValid, "Flagger not recognized."); 
        
         // if the message doesn't exists or has been deleted
        require(!messageList[msgID].isDeleted, "Invalid msgID!"); 
        
        // if the message has been already flagged
        require(!userList[flaggerName].flaggedMessages[msgID], 
        "Sorry, you can only flag a msg once!");
        
        userList[flaggerName].flaggedMessages[msgID] = true; // added to list of flagged messages
       
        if (++messageList[msgID].flags > numActiveUsers) {
            if (messageList[msgID].isAnonymous) {
                messageList[msgID].isAnonymous = false;
            } else {
                messageList[msgID].isDeleted = true; 
            }
        }
    }
 
    function getMessage(string userName, uint messageID) public view returns (string, string) {
         // if the user is unregistered, send an error
        require(
            userList[userName].isValid &&
            messageID < messageList.length && 
            !messageList[messageID].isDeleted, 
            "Username or MessageId invalid."
        ); 
        
        string memory messagerName;
        messageList[messageID].isAnonymous ?
            messagerName = REDACTED :  
            messagerName = messageList[messageID].author; 
        
        // All the encoding for string concatenation: 
        // https://ethereum.stackexchange.com/a/56337
        return (
            string(abi.encodePacked("Message: ", messageList[messageID].text)), 
            string(abi.encodePacked("Sender: ", messagerName)));
    }
    
    function logAllMessages(string userName) public  {
        // if the userName unregistered, send an error
        require(userList[userName].isValid, "User not recognized."); 
        // string[] messages; 
        uint index = 0;
        // uint length = 0;
        
        while(index < numMessages) {
            if (!messageList[index].isDeleted) {
                 if (messageList[index].isAnonymous) {
                    emit ValidMessage(string(abi.encodePacked(
                        "MessageID: ", uint2str(index), 
                        " Message: ",messageList[index].text, 
                        " and Sender: ", REDACTED))); 
                 }
                 else {
                     emit ValidMessage(string(abi.encodePacked(
                         "MessageID: ", uint2str(index), 
                         " Message: ",messageList[index].text, 
                         " and Sender: ", messageList[index].author)));
                 }
            }
            index++;
        }
    }
    
    // Helper function to covert uint -> string
    // Cite: https://github.com/provable-things/ethereum-api/blob/master/oraclizeAPI_0.5.sol
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    


}