module.exports = {
  networks: {
    development: {
     host: "127.0.0.1",     // Localhost (default: none)
     port: 8545,            // Standard Ethereum port (default: none)
     network_id: "*",       // Any network (default: none)
    },
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.5.13",
      settings: {
       optimizer: {
         enabled: true,
         runs: 400
       },
       evmVersion: "istanbul"
      }
    }
  }
}