import { createConfig, http } from 'wagmi'
import { anvil, sepolia } from 'wagmi/chains'

export const config = createConfig({
  chains: [anvil, sepolia],
  transports: {
    [anvil.id]: http(),
    [sepolia.id]: http(),
  },
})
