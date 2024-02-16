// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract InvitationCodeGenerator {
    bytes32 private constant base32hexChars = "0123456789ABCDEFGHIJKLMNPQRSTUVX";
    string private currentString = "000";

    function generate() internal returns (string memory) {
        return _encodeBase32hex(_getNextAlphanumericString());
    }

    function _encodeBase32hex(string memory input) private pure returns (string memory) {
        bytes memory inputData = bytes(input);
        bytes memory encodedData = new bytes(inputData.length * 8 / 5 + 1);

        uint256 encodedIndex = 0;
        uint256 currentByte = 0;
        uint256 bitsRemaining = 0;

        for (uint256 i = 0; i < inputData.length; i++) {
            currentByte = (currentByte << 8) | uint8(inputData[i]);
            bitsRemaining += 8;

            while (bitsRemaining >= 5) {
                bitsRemaining -= 5;
                uint8 index = uint8((currentByte >> bitsRemaining) & 0x1F);
                encodedData[encodedIndex++] = base32hexChars[index];
            }
        }

        if (bitsRemaining > 0) {
            currentByte <<= 5 - bitsRemaining;
            uint8 index = uint8(currentByte & 0x1F);
            encodedData[encodedIndex++] = base32hexChars[index];
        }

        return string(encodedData);
    }

    function _getNextAlphanumericString() private returns (string memory) {
        require(!_reachedMaximumValue(), "Reached maximum value");

        string memory result = currentString;
        _incrementCurrentString();

        return result;
    }

    function _incrementCurrentString() private {
        bytes memory currentBytes = bytes(currentString);

        for (uint256 i = currentBytes.length - 1; i >= 0; i--) {
            if (currentBytes[i] == bytes1("9")) {
                currentBytes[i] = bytes1("A");
            } else if (currentBytes[i] == bytes1("Z")) {
                currentBytes[i] = bytes1("0");
            } else {
                currentBytes[i] = bytes1(uint8(currentBytes[i]) + 1);
                break;
            }
        }

        currentString = string(currentBytes);
    }

    function _reachedMaximumValue() private view returns (bool) {
        return keccak256(bytes(currentString)) == keccak256(bytes("ZZZ"));
    }
}
