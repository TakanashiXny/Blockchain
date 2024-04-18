// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.15 <0.9.0;
pragma abicoder v2;

contract StudentContract {
    struct Student {
        uint256 id;
        string name;
        string sex;
        uint256 age;
        string dept;
    }

    address admin;
    Student[] students;
    uint256[] ids;
    uint256 count = 0;
    mapping(uint256 => uint256) indexMapping; // id映射index
    mapping(uint256 => bool) isExistMapping;

    constructor() {
        admin = msg.sender;
    }

    function insert(
        uint256 _id,
        string memory _name,
        string memory _sex,
        uint256 _age,
        string memory _dept
    ) public {
        // TODO:插入一条学生记录
        require(admin == msg.sender);
        if (exist_by_id(_id)) {
            return;
        }
        students.push(Student(_id, _name, _sex, _age, _dept));
        ids.push(_id);
        count++;
        indexMapping[_id] = count - 1;
        isExistMapping[_id] = true;

        emit Insert(_id);
    }

    event Insert(uint256 id);

    function exist_by_id(uint256 _id) public view returns (bool isExist) {
        // TODO:查找系统中是否存在某个学号
        for (uint i = 0; i < count; i++) {
            if (students[i].id == _id) {
                return true;
            }
        }
        return false;
    }

    function select_count() public view returns (uint256 _count) {
        // TODO:查找系统中的学生数量
        return count;
    }

    function select_all_id() public view returns (uint256[] memory _ids) {
        // TODO:查找系统中所有的学号
        uint256 countNonZero = 0;
        // 先计算有效的学号数量
        for (uint256 i = 0; i < ids.length; i++) {
            if (ids[i] != 0) {
                countNonZero++;
            }
        }

        // 创建具有正确长度的内存数组
        _ids = new uint256[](countNonZero);

        uint256 index = 0;
        // 将有效的学号添加到内存数组中
        for (uint256 i = 0; i < ids.length; i++) {
            if (ids[i] != 0) {
                _ids[index] = ids[i];
                index++;
            }
        }

        return _ids;
    }

    function select_id(uint256 _id) public view returns (Student memory) {
        // TODO:查找指定学号的学生信息
        uint index = indexMapping[_id];
        return students[index];
    }

    function delete_by_id(uint256 _id) public {
        // TODO:删除指定学号的学生信息
        require(admin == msg.sender);
        for (uint i = 0; i < students.length; i++) {
            if (ids[i] != 0 && students[i].id == _id) {
                delete(students[i]);
                delete(ids[i]);
                count--;
                isExistMapping[_id] = false;
                break;
            }
        }
    }
}
