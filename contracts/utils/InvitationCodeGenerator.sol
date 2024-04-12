// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract InvitationCodeGenerator {
    bytes32 private constant _base32hexChars = "123456789ABCDEFGHJKLMNPQRTUVWXYZ";
    string private _currentString = "00000";

    function generateCode() internal returns (string memory) {
        return encodeBase32hex(_getNextAlphanumericString());
    }

    function _getNextAlphanumericString() private returns (string memory) {
        require(!_reachedMaximumValue(), "Reached maximum value");

        string memory result = _currentString;
        _incrementCurrentString();

        return result;
    }

    function _incrementCurrentString() internal {
        bytes memory currentBytes = bytes(_currentString);

        for (uint256 i = currentBytes.length - 1; i >= 0; i--) {
            if (currentBytes[i] == bytes1("9")) {
                currentBytes[i] = bytes1("a");
                break;
            } else if (currentBytes[i] == bytes1("z")) {
                currentBytes[i] = bytes1("A");
                break;
            } else if (currentBytes[i] == bytes1("Z")) {
                currentBytes[i] = bytes1("0");
            } else {
                currentBytes[i] = bytes1(uint8(currentBytes[i]) + 1);
                break;
            }
        }

        _currentString = string(currentBytes);
    }

    function _reachedMaximumValue() private view returns (bool) {
        return keccak256(bytes(_currentString)) == keccak256(bytes("ZZZZZ"));
    }

    function encodeBase32hex(string memory input) private pure returns (string memory) {
        bytes memory inputData = bytes(input);
        require(inputData.length == 5, "Input length should be 5");

        bytes memory encodedData = new bytes(8);

        uint256 encodedIndex = 0;
        uint256 currentByte = 0;
        uint256 bitsRemaining = 0;

        for (uint256 i = 0; i < inputData.length; i++) {
            currentByte = (currentByte << 8) | uint8(inputData[i]);
            bitsRemaining += 8;

            while (bitsRemaining >= 5) {
                bitsRemaining -= 5;
                uint8 index = uint8((currentByte >> bitsRemaining) & 0x1F);
                encodedData[encodedIndex++] = _base32hexChars[index];
            }
        }

        if (bitsRemaining > 0) {
            currentByte <<= 5 - bitsRemaining;
            uint8 index = uint8(currentByte & 0x1F);
            encodedData[encodedIndex++] = _base32hexChars[index];
        }

        return string(encodedData);
    }
}
