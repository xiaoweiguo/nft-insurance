// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

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
     * @dev Get the last node in the linked list.
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
     * @dev Check if a node exists in the linked list.
     * @param _linkedList The linked list.
     * @param _node The node to check.
     * @return True if the node exists, false otherwise.
     */
    function _isNodeExist(LinkedList storage _linkedList, bytes32 _node) internal view returns (bool) {
        return _linkedList.list[_node].current != ZERO;
    }

    /**
     * @dev Add a node to the end of the linked list.
     * @param _linkedList The linked list.
     * @param _node The node to add.
     * @return True if the node was added successfully, false if the node already exists.
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
     * @dev Insert a new node after a specified node in the linked list.
     * @param _linkedList The linked list.
     * @param _currentNode The node after which to insert the new node.
     * @param _newNode The new node to insert.
     * @return True if the new node was inserted successfully, false if the new node already exists or the specified node was not found.
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
     * @dev Get the node with the specified value from the linked list.
     * @param _linkedList The linked list.
     * @param _node The value of the node to get.
     * @return The node.
     */
    function _getNode(LinkedList storage _linkedList, bytes32 _node) private view returns (Node memory) {
        return _linkedList.list[_node];
    }

    /**
     * @dev Remove a node from the linked list
