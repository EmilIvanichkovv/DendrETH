#[cfg(not(feature = "library"))]
use cosmwasm_std::{
    entry_point, to_binary, Binary, Deps, DepsMut, Env, MessageInfo, Response, StdError, StdResult,
};
use crate::msg::{ConfigResponse, ExecuteMsg, InstantiateMsg, QueryMsg};

// use cw2::set_contract_version;

use crate::error::ContractError;
use crate::state::{BeaconBlockHeader, CONFIG};

/*
// version info for migration info
const CONTRACT_NAME: &str = "crates.io:light-client";
const CONTRACT_VERSION: &str = env!("CARGO_PKG_VERSION");
*/

#[cfg_attr(not(feature = "library"), entry_point)]
pub fn instantiate(
    _deps: DepsMut,
    _env: Env,
    _info: MessageInfo,
    _msg: InstantiateMsg,
) -> Result<Response, ContractError> {
    let header: BeaconBlockHeader = BeaconBlockHeader{
        slot: _msg.slot,
        proposer_index: _msg.proposer_index,
        parent_root: _msg.parent_root,
        state_root: _msg.state_root,
        body_root: _msg.body_root,
    };
    CONFIG.save(_deps.storage, &header)?;
    Ok(Response::default())

}

#[cfg_attr(not(feature = "library"), entry_point)]
pub fn execute(
    _deps: DepsMut,
    _env: Env,
    _info: MessageInfo,
    _msg: ExecuteMsg,
) -> Result<Response, ContractError> {
    unimplemented!()
}

#[cfg_attr(not(feature = "library"), entry_point)]
pub fn query(_deps: Deps, _env: Env, _msg: QueryMsg) -> StdResult<Binary> {
    match _msg {
        QueryMsg::BeaconBlockHeader {} => to_binary::<ConfigResponse>(&CONFIG.load(_deps.storage)?.into()),
    }
}

#[cfg(test)]
mod tests {}
