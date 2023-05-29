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

    function _getLastNode(
        LinkedList storage _linkedList
    ) internal view returns (Node memory) {
        Node memory currentNode = _linkedList.list[ZERO];
        while (currentNode.next != ZERO) {
            currentNode = _linkedList.list[currentNode.next];
        }
        return currentNode;
    }

    function _isNodeExist(
        LinkedList storage _linkedList,
        bytes32 _node
    ) internal view returns (bool) {
        return _linkedList.list[_node].current != ZERO;
    }

    function _add(
        LinkedList storage _linkedList,
        bytes32 _node
    ) private returns (bool) {
        Node memory currentNode = _getLastNode(_linkedList);
        if (_isNodeExist(_linkedList, _node)) {
            return false;
        } else {
            _linkedList.list[currentNode.current].next = _node;
            _linkedList.list[_node] = Node(_node, currentNode.current, ZERO);
        }

        return true;
    }

    function _insertAfter(
        LinkedList storage _linkedList,
        bytes32 _currentNode,
        bytes32 _newNode
    ) private returns (bool) {
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

    function _getNode(
        LinkedList storage _linkedList,
        bytes32 _node
    ) private view returns (Node memory) {
        return _linkedList.list[_node];
    }

    function _removeNode(
        LinkedList storage _linkedList,
        bytes32 _node
    ) internal returns (bool) {
        if (!_isNodeExist(_linkedList, _node)) {
            return false;
        } else {
            Node storage prevNode = _linkedList.list[
                _linkedList.list[_node].prev
            ];
            Node memory currentNode = _linkedList.list[_node];
            bytes32 next = currentNode.next;
            Node storage nextNode = _linkedList.list[
                _linkedList.list[_node].next
            ];
            if (next != ZERO) {
                nextNode.prev = prevNode.current;
            }
            prevNode.next = nextNode.current;
            delete _linkedList.list[_node];
        }
        return true;
    }

    function getSize(
        LinkedList storage _linkedList
    ) external view returns (uint256) {
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

    function insertAfter(
        Bytes32LinkedList storage _linkedList,
        bytes32 _currentNode,
        bytes32 _newNode
    ) internal returns (bool) {
        return _insertAfter(_linkedList._inner, _currentNode, _newNode);
    }

    function add(
        Bytes32LinkedList storage _linkedList,
        bytes32 _node
    ) internal returns (bool) {
        return _add(_linkedList._inner, _node);
    }

    function remove(
        Bytes32LinkedList storage _linkedList,
        bytes32 _node
    ) internal returns (bool) {
        return _removeNode(_linkedList._inner, _node);
    }

    function getNode(
        Bytes32LinkedList storage _linkedList,
        bytes32 _node
    ) internal view returns (Node memory) {
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

    function _addressToBytes32(address value) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(value)));
    }

    function _bytes32ToAddress(bytes32 value) internal pure returns (address) {
        return address(uint160(uint256(value)));
    }

    function insertAfter(
        AddressLinkedList storage _linkedList,
        address _currentNode,
        address _newNode
    ) internal returns (bool) {
        return
            _insertAfter(
                _linkedList._inner,
                _addressToBytes32(_currentNode),
                _addressToBytes32(_newNode)
            );
    }

    function add(
        AddressLinkedList storage _linkedList,
        address _node
    ) internal returns (bool) {
        return _add(_linkedList._inner, _addressToBytes32(_node));
    }

    function remove(
        AddressLinkedList storage _linkedList,
        address _node
    ) internal returns (bool) {
        return _removeNode(_linkedList._inner, _addressToBytes32(_node));
    }

    function getNode(
        AddressLinkedList storage _linkedList,
        address _node
    ) internal view returns (AddressNode memory) {
        Node memory node = _getNode(
            _linkedList._inner,
            _addressToBytes32(_node)
        );
        return
            AddressNode(
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

    function _bytes32ToUint(bytes32 _value) internal pure returns (uint256) {
        return uint256(_value);
    }

    function _uintToBytes32(uint256 value) internal pure returns (bytes32) {
        return bytes32(value);
    }

    function insertAfter(
        UintLinkedList storage _linkedList,
        uint256 _currentNode,
        uint256 _newNode
    ) internal returns (bool) {
        return
            _insertAfter(
                _linkedList._inner,
                _uintToBytes32(_currentNode),
                _uintToBytes32(_newNode)
            );
    }

    function add(
        UintLinkedList storage _linkedList,
        uint256 _node
    ) internal returns (bool) {
        return _add(_linkedList._inner, _uintToBytes32(_node));
    }

    function remove(
        UintLinkedList storage _linkedList,
        uint256 _node
    ) internal returns (bool) {
        return _removeNode(_linkedList._inner, _uintToBytes32(_node));
    }

    function getNode(
        UintLinkedList storage _linkedList,
        uint256 _node
    ) internal view returns (UintNode memory) {
        Node memory node = _getNode(_linkedList._inner, _uintToBytes32(_node));
        return
            UintNode(
                _bytes32ToUint(node.current),
                _bytes32ToUint(node.prev),
                _bytes32ToUint(node.next)
            );
    }
}
