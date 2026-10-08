import { loadConfig } from './config.js';
import { BridgeServer } from './server.js';

const config = loadConfig();
const bridge = new BridgeServer(config);

try {
  const address = await bridge.start();
  console.log(`THE_ONE_BRIDGE_READY ${address.url}`);
  console.log(`AUTH ${config.token ? 'TOKEN_REQUIRED' : 'LOOPBACK_ONLY_NO_TOKEN'}`);
} catch (error) {
  console.error('THE_ONE_BRIDGE_FAILED', error);
  process.exitCode = 1;
}

for (const signal of ['SIGINT', 'SIGTERM'] as const) {
  process.on(signal, () => {
    void bridge.stop().finally(() => process.exit(0));
  });
}
