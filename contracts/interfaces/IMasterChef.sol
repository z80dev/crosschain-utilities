// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMasterChef {
    function POOL_PERCENTAGE() external view returns (uint256);

    function TREASURY_PERCENTAGE() external view returns (uint256);

    function add(
        uint256 _allocPoint,
        address _lpToken,
        address _rewarder
    ) external;

    function beets() external view returns (address);

    function beetsPerBlock() external view returns (uint256);

    function deposit(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) external;

    function emergencyWithdraw(uint256 _pid, address _to) external;

    function harvest(uint256 _pid, address _to) external;

    function lpTokens(uint256) external view returns (address);

    function owner() external view returns (address);

    function pendingBeets(uint256 _pid, address _user) external view returns (uint256 pending);

    function poolInfo(uint256)
        external
        view
        returns (
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accBeetsPerShare
        );

    function poolLength() external view returns (uint256);

    function renounceOwnership() external;

    function rewarder(uint256) external view returns (address);

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        address _rewarder,
        bool overwrite
    ) external;

    function startBlock() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function treasury(address _treasuryAddress) external;

    function treasuryAddress() external view returns (address);

    function updateEmissionRate(uint256 _beetsPerBlock) external;

    function userInfo(uint256, address) external view returns (uint256 amount, uint256 rewardDebt);

    function withdrawAndHarvest(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) external;
}
