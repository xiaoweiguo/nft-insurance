// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title LinkedListLib
 * @dev Library for managing linked lists in Solidity.
 */
library LinkedListLib {
    bytes32 constant ZERO = bytes32(0);

    struct Node {
        bytes32 current;
        bytes32 prev;
        bytes32 next;
    }

    struct LinkedList {
        mapping(bytes32 => Node) list;
    }

    /**
     * @dev Retrieves the last node in the linked list.
     * @param _linkedList The linked list.
     * @return The last node.
     */
    function _getLastNode(LinkedList storage _linkedList) internal view returns (Node memory) {
        Node memory currentNode = _linkedList.list[ZERO];
        while (currentNode.next != ZERO) {
            currentNode = _linkedList.list[currentNode.next];
        }
        return currentNode;
    }

    /**
     * @dev Checks if a node exists in the linked list.
     * @param _linkedList The linked list.
     * @param _node The node to check.
     * @return True if the node exists, false otherwise.
     */
    function _isNodeExist(LinkedList storage _linkedList, bytes32 _node) internal view returns (bool) {
        return _linkedList.list[_node].current != ZERO;
    }

    /**
     * @dev Adds a node to the end of the linked list.
     * @param _linkedList The linked list.
     * @param _node The node to add.
     * @return True if the node was added successfully, false otherwise.
     */
    function _add(LinkedList storage _linkedList, bytes32 _node) private returns (bool) {
        Node memory currentNode = _getLastNode(_linkedList);
        if (_isNodeExist(_linkedList, _node)) {
            return false;
        } else {
            _linkedList.list[currentNode.current].next = _node;
            _linkedList.list[_node] = Node(_node, currentNode.current, ZERO);
        }
        return true;
    }

    /**
     * @dev Inserts a new node after a specified node in the linked list.
     * @param _linkedList The linked list.
     * @param _currentNode The node after which the new node will be inserted.
     * @param _newNode The new node to insert.
     * @return True if the node was inserted successfully, false otherwise.
     */
    function _insertAfter(LinkedList storage _linkedList, bytes32 _currentNode, bytes32 _newNode) private returns (bool) {
        if (_isNodeExist(_linkedList, _newNode)) {
            return false;
        } else if (_getLastNode(_linkedList).current == _currentNode) {
            return _add(_linkedList, _newNode);
        } else {
            bytes32 nextNode = _linkedList.list[_currentNode].next;
            _linkedList.list[_newNode] = Node(_newNode, _currentNode, nextNode);
            _linkedList.list[nextNode].prev = _newNode;
            _linkedList.list[_currentNode].next = _newNode;
        }
        return true;
    }

    /**
     * @dev Retrieves a node from the linked list.
     * @param _linkedList The linked list.
     * @param _node The node to retrieve.
     * @return The node.
     */
    function _getNode(LinkedList storage _linkedList, bytes32 _node) private view returns (Node memory) {
        return _linkedList.list[_node];
    }

    /**
     * @dev Removes a node from the linked list.
     * @param _linkedList The linked list.
     * @param _node The node to remove.
     * @return True if the node was removed successfully, false otherwise.
     */
    function _removeNode(LinkedList storage _linkedList, bytes32 _node) internal returns (bool) {
        if (!_isNodeExist(_linkedList, _node)) {
            return false;
        } else {
            Node storage prevNode = _linkedList.list[_linkedList.list[_node].prev];
            Node memory currentNode = _linkedList.list[_node];
            bytes32 next = currentNode.next;
            Node storage nextNode = _linkedList.list[_linkedList.list[_node].next];
            if (next != ZERO) {
                nextNode.prev = prevNode.current;
            }
            prevNode.next = nextNode.current;
            delete _linkedList.list[_node];
        }
        return true;
    }

    /**
     * @dev Retrieves the size of the linked list.
     * @param _linkedList The linked list.
     * @return The size of the linked list.
     */
    function getSize(LinkedList storage _linkedList) external view returns (uint256) {
        bytes32 current = ZERO;
        uint256 size = 0;
        while (_linkedList.list[current].next != ZERO) {
            size++;
            current = _linkedList.list[current].next;
        }
        return size;
    }

    struct Bytes32LinkedList {
        LinkedList _inner;
    }

    /**
     * @dev Inserts a new bytes32 node after a specified bytes32 node in the linked list.
     * @param _linkedList The linked list.
     * @param _currentNode The node after which the new node will be inserted.
     * @param _newNode The new node to insert.
     * @return True if the node was inserted successfully, false otherwise.
     */
    function insertAfter(Bytes32LinkedList storage _linkedList, bytes32 _currentNode, bytes32 _newNode) internal returns (bool) {
        return _insertAfter(_linkedList._inner, _currentNode, _newNode);
    }

    /**
     * @dev Adds a new bytes32 node to the end of the linked list.
     * @param _linkedList The linked list.
     * @param _node The node to add.
     * @return True if the node was added successfully, false otherwise.
     */
    function add(Bytes32LinkedList storage _linkedList, bytes32 _node) internal returns (bool) {
        return _add(_linkedList._inner, _node);
    }

    /**
     * @dev Removes a bytes32 node from the linked list.
     * @param _linkedList The linked list.
     * @param _node The node to remove.
     * @return True if the node was removed successfully, false otherwise.
     */
    function remove(Bytes32LinkedList storage _linkedList, bytes32 _node) internal returns (bool) {
        return _removeNode(_linkedList._inner, _node);
    }

    /**
     * @dev Retrieves a bytes32 node from the linked list.
     * @param _linkedList The linked list.
     * @param _node The node to retrieve.
     * @return The node.
     */
    function getNode(Bytes32LinkedList storage _linkedList, bytes32 _node) internal view returns (Node memory) {
        return _getNode(_linkedList._inner, _node);
    }

    struct AddressLinkedList {
        LinkedList _inner;
    }

    struct AddressNode {
        address current;
        address prev;
        address next;
    }

    /**
     * @dev Converts an address to bytes32.
     * @param value The address to convert.
     * @return The converted bytes32 value.
     */
    function _addressToBytes32(address value) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(value)));
    }

    /**
     * @dev Converts a bytes32 value to an address.
     * @param value The bytes32 value to convert.
     * @return The converted address value.
     */
    function _bytes32ToAddress(bytes32 value) internal pure returns (address) {
        return address(uint160(uint256(value)));
    }

    /**
     * @dev Inserts a new address node after a specified address node in the linked list.
     * @param _linkedList The linked list.
     * @param _currentNode The node after which the new node will be inserted.
     * @param _newNode The new node to insert.
     * @return True if the node was inserted successfully, false otherwise.
     */
    function insertAfter(AddressLinkedList storage _linkedList, address _currentNode, address _newNode) internal returns (bool) {
        return _insertAfter(_linkedList._inner, _addressToBytes32(_currentNode), _addressToBytes32(_newNode));
    }

    /**
     * @dev Adds a new address node to the end of the linked list.
     * @param _linkedList The linked list.
     * @param _node The node to add.
     * @return True if the node was added successfully, false otherwise.
     */
    function add(AddressLinkedList storage _linkedList, address _node) internal returns (bool) {
        return _add(_linkedList._inner, _addressToBytes32(_node));
    }

    /**
     * @dev Removes an address node from the linked list.
     * @param _linkedList The linked list.
     * @param _node The node to remove.
     * @return True if the node was removed successfully, false otherwise.
     */
    function remove(AddressLinkedList storage _linkedList, address _node) internal returns (bool) {
        return _removeNode(_linkedList._inner, _addressToBytes32(_node));
    }

    /**
     * @dev Retrieves an address node from the linked list.
     * @param _linkedList The linked list.
     * @param _node The node to retrieve.
     * @return The node.
     */
    function getNode(AddressLinkedList storage _linkedList, address _node) internal view returns (AddressNode memory) {
        Node memory node = _getNode(_linkedList._inner, _addressToBytes32(_node));
        return AddressNode(
            _bytes32ToAddress(node.current),
            _bytes32ToAddress(node.prev),
            _bytes32ToAddress(node.next)
        );
    }

    struct UintLinkedList {
        LinkedList _inner;
    }

    struct UintNode {
        uint256 current;
        uint256 prev;
        uint256 next;
    }

    /**
     * @dev Converts a bytes32 value to a uint256.
     * @param _value The bytes32 value to convert.
     * @return The converted uint256 value.
     */
    function _bytes32ToUint(bytes32 _value) internal pure returns (uint256) {
        return uint256(_value);
    }

    /**
     * @dev Converts a uint256 to bytes32.
     * @param value The uint256 value to convert.
     * @return The converted bytes32 value.
     */
    function _uintToBytes32(uint256 value) internal pure returns (bytes32) {
        return bytes32(value);
    }

    /**
     * @dev Inserts a new uint256 node after a specified uint256 node in the linked list.
     * @param _linkedList The linked list.
     * @param _currentNode The node after which the new node will be inserted.
     * @param _newNode The new node to insert.
     * @return True if the node was inserted successfully, false otherwise.
     */
    function insertAfter(UintLinkedList storage _linkedList, uint256 _currentNode, uint256 _newNode) internal returns (bool) {
        return _insertAfter(_linkedList._inner, _uintToBytes32(_currentNode), _uintToBytes32(_newNode));
    }

    /**
     * @dev Adds a new uint256 node to the end of the linked list.
     * @param _linkedList The linked list.
     * @param _node The node to add.
     * @return True if the node was added successfully, false otherwise.
     */
    function add(UintLinkedList storage _linkedList, uint256 _node) internal returns (bool) {
        return _add(_linkedList._inner, _uintToBytes32(_node));
    }

    /**
     * @dev Removes a uint256 node from the linked list.
     * @param _linkedList The linked list.
     * @param _node The node to remove.
     * @return True if the node was removed successfully, false otherwise.
     */
    function remove(UintLinkedList storage _linkedList, uint256 _node) internal returns (bool) {
        return _removeNode(_linkedList._inner, _uintToBytes32(_node));
    }

    /**
     * @dev Retrieves a uint256 node from the linked list.
     * @param _linkedList The linked list.
     * @param _node The node to retrieve.
     * @return The node.
     */
    function getNode(UintLinkedList storage _linkedList, uint256 _node) internal view returns (UintNode memory) {
        Node memory node = _getNode(_linkedList._inner, _uintToBytes32(_node));
        return UintNode(
            _bytes32ToUint(node.current),
            _bytes32ToUint(node.prev),
            _bytes32ToUint(node.next)
        );
    }
}
