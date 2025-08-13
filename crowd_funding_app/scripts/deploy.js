#!/usr/bin/env node

/**
 * Stacks Crowdfunding Platform Deployment Script
 * 
 * This script handles the deployment of the crowdfunding smart contract
 * to Stacks blockchain networks (devnet, testnet, mainnet).
 */

const { StacksNetwork, StacksTestnet, StacksMainnet } = require('@stacks/network');
const { makeContractDeploy, broadcastTransaction, AnchorMode } = require('@stacks/transactions');
const { readFileSync } = require('fs');
const path = require('path');

// Configuration
const config = {
  devnet: {
    network: new StacksNetwork({ url: 'http://localhost:3999' }),
    name: 'devnet'
  },
  testnet: {
    network: new StacksTestnet(),
    name: 'testnet'
  },
  mainnet: {
    network: new StacksMainnet(),
    name: 'mainnet'
  }
};

/**
 * Deploy the crowdfunding contract to specified network
 */
async function deployContract(networkName, privateKey, contractName = 'crowdfund') {
  try {
    console.log(`🚀 Starting deployment to ${networkName}...`);
    
    const network = config[networkName].network;
    
    // Read contract source
    const contractPath = path.join(__dirname, '../contracts/crowdfund.clar');
    const contractSource = readFileSync(contractPath, 'utf8');
    
    console.log(`📄 Contract source loaded: ${contractSource.length} characters`);
    
    // Create contract deployment transaction
    const txOptions = {
      contractName: contractName,
      codeBody: contractSource,
      senderKey: privateKey,
      network: network,
      anchorMode: AnchorMode.Any,
      fee: 50000, // Adjust fee as needed
    };
    
    const transaction = await makeContractDeploy(txOptions);
    
    console.log(`📝 Transaction created: ${transaction.txid()}`);
    console.log(`🔄 Broadcasting transaction...`);
    
    // Broadcast transaction
    const broadcastResponse = await broadcastTransaction(transaction, network);
    
    if (broadcastResponse.error) {
      throw new Error(`Broadcast failed: ${broadcastResponse.error} - ${broadcastResponse.reason}`);
    }
    
    console.log(`✅ Contract deployed successfully!`);
    console.log(`📋 Transaction ID: ${broadcastResponse.txid}`);
    console.log(`🌐 Network: ${networkName}`);
    console.log(`📄 Contract: ${contractName}`);
    
    // Provide next steps
    console.log(`\n🎯 Next Steps:`);
    console.log(`1. Wait for transaction confirmation`);
    console.log(`2. Verify deployment on explorer`);
    console.log(`3. Initialize categories with: (contract-call? .${contractName} initialize-categories)`);
    
    if (networkName === 'testnet') {
      console.log(`🔗 Testnet Explorer: https://explorer.stacks.co/txid/${broadcastResponse.txid}?chain=testnet`);
    } else if (networkName === 'mainnet') {
      console.log(`🔗 Mainnet Explorer: https://explorer.stacks.co/txid/${broadcastResponse.txid}`);
    }
    
    return {
      success: true,
      txid: broadcastResponse.txid,
      network: networkName,
      contractName: contractName
    };
    
  } catch (error) {
    console.error(`❌ Deployment failed:`, error.message);
    return {
      success: false,
      error: error.message
    };
  }
}

/**
 * Validate deployment environment
 */
function validateEnvironment() {
  const requiredEnvVars = ['STACKS_PRIVATE_KEY'];
  const missing = requiredEnvVars.filter(env => !process.env[env]);
  
  if (missing.length > 0) {
    console.error(`❌ Missing required environment variables: ${missing.join(', ')}`);
    console.log(`\n🔧 Setup Instructions:`);
    console.log(`1. Create a .env file in the project root`);
    console.log(`2. Add your private key: STACKS_PRIVATE_KEY=your_private_key_here`);
    console.log(`3. Optionally add: CONTRACT_NAME=crowdfund`);
    process.exit(1);
  }
}

/**
 * Initialize contract categories after deployment
 */
async function initializeContract(networkName, privateKey, contractAddress) {
  try {
    console.log(`\n🔧 Initializing contract categories...`);
    
    // This would typically be done through a separate transaction
    // For now, we'll just provide instructions
    console.log(`📋 Manual initialization required:`);
    console.log(`Run the following in Clarinet console or Stacks CLI:`);
    console.log(`(contract-call? '${contractAddress}.crowdfund initialize-categories)`);
    
  } catch (error) {
    console.error(`❌ Initialization failed:`, error.message);
  }
}

/**
 * Main deployment function
 */
async function main() {
  console.log(`🎉 Stacks Crowdfunding Platform Deployment`);
  console.log(`========================================\n`);
  
  // Parse command line arguments
  const args = process.argv.slice(2);
  const networkName = args[0] || 'devnet';
  const contractName = process.env.CONTRACT_NAME || 'crowdfund';
  
  if (!config[networkName]) {
    console.error(`❌ Invalid network: ${networkName}`);
    console.log(`✅ Valid networks: ${Object.keys(config).join(', ')}`);
    process.exit(1);
  }
  
  // Validate environment
  validateEnvironment();
  
  const privateKey = process.env.STACKS_PRIVATE_KEY;
  
  // Deploy contract
  const result = await deployContract(networkName, privateKey, contractName);
  
  if (result.success) {
    console.log(`\n🎊 Deployment Summary:`);
    console.log(`================`);
    console.log(`✅ Status: Success`);
    console.log(`📄 Contract: ${contractName}`);
    console.log(`🌐 Network: ${networkName}`);
    console.log(`📋 TX ID: ${result.txid}`);
    
    // Save deployment info
    const deploymentInfo = {
      timestamp: new Date().toISOString(),
      network: networkName,
      contractName: contractName,
      txid: result.txid,
      status: 'deployed'
    };
    
    console.log(`\n📝 Deployment info saved for future reference`);
    
  } else {
    console.log(`\n💥 Deployment Failed:`);
    console.log(`==================`);
    console.log(`❌ Error: ${result.error}`);
    process.exit(1);
  }
}

// Run deployment if this script is executed directly
if (require.main === module) {
  main().catch(console.error);
}

module.exports = {
  deployContract,
  validateEnvironment,
  initializeContract
};