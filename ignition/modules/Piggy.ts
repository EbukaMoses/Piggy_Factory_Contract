// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";


const Piggy = buildModule("Piggy", (m) => {


  const Kolo = m.contract("KoloFactory");

  return { Kolo };
});

export default Piggy;
