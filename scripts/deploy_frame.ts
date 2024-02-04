import net from "net";

import { ethers, JsonRpcProvider } from "ethers";

import { connect_kettle, deploy_artifact, deploy_artifact_direct, attach_artifact, kettle_advance, kettle_execute, derive_key } from "./common"

import * as LocalConfig from '../deployment.json'

/* Contract utils */
export async function setup_frame(kettle: net.Socket | string, FRAME: ethers.Contract) {
  const offchainEnclaveTxData = await FRAME.offchain_Enclave.populateTransaction();
  let resp = await kettle_execute(kettle, offchainEnclaveTxData.to, offchainEnclaveTxData.data);

  let executionResult = JSON.parse(resp);
  if (executionResult.Success === undefined) {
    throw("execution did not succeed: "+JSON.stringify(resp));
  }

  console.log("set priv");
}

async function deploy() {
  const kettle = connect_kettle(LocalConfig.KETTLE_RPC);

  const provider = new JsonRpcProvider(LocalConfig.RPC_URL);
  const wallet = new ethers.Wallet(LocalConfig.PRIVATE_KEY, provider);
  const ADDR_OVERRIDES: {[key: string]: string} = LocalConfig.ADDR_OVERRIDES;
  const KM = await attach_artifact(LocalConfig.KEY_MANAGER_SN_ARTIFACT, wallet, ADDR_OVERRIDES[LocalConfig.KEY_MANAGER_SN_ARTIFACT]);

  const FRAME = await deploy_artifact_direct(LocalConfig.FRAME_ARTIFACT, wallet, KM.target);

  await kettle_advance(kettle);
  await derive_key(await FRAME.getAddress(), kettle, KM);

  await kettle_advance(kettle);
  await setup_frame(kettle, FRAME);
}

deploy().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
