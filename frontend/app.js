// GLM AUDIT - Frontend Application
// Loads audit report data and handles NFT minting

const SEPOLIA_CHAIN_ID = 11155111;
const EAS_CONTRACT = '0xC2679fBD37d54388Ce493F1DB75320D236e1815e';
const NFT_CONTRACT = '0x0000000000000000000000000000000000000000'; // Update after deployment

// Sample audit report data (in production, load from JSON file)
const SAMPLE_REPORT = {
    contract: {
        file: 'VulnerableBank.sol',
        name: 'VulnerableBank',
        network: 'Sepolia',
        address: '0x1234567890abcdef1234567890abcdef12345678'
    },
    status: {
        critical: 1,
        high: 0,
        medium: 0,
        low: 0,
        informational: 2
    },
    score: 2,
    findings: [
        {
            id: 1,
            title: 'Reentrancy in withdraw()',
            severity: 'critical',
            confidence: 95,
            contract: 'VulnerableBank',
            function: 'withdraw()',
            location: 'line 14-18',
            description: 'The withdraw() function sends ETH via low-level call before updating balances[msg.sender] to 0. An attacker contract can re-enter withdraw() in its receive() fallback, repeatedly withdrawing the same balance until the contract is drained.',
            fix: 'Use checks-effects-interactions pattern: update state before external call, or use ReentrancyGuard.',
            poc: true,
            pocPassed: true
        }
    ],
    verification: {
        staticAnalysis: {
            tool: 'Slither',
            status: 'pass',
            findings: 3
        },
        pocExecution: {
            tool: 'Foundry',
            status: 'pass',
            test: 'test_reentrancy_drains_bank'
        },
        fuzzTesting: {
            tool: 'Foundry',
            status: 'pass',
            runs: 256
        }
    },
    attestation: {
        uid: '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
        network: 'sepolia',
        txHash: '0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890'
    },
    certificate: {
        tier: 'Gold',
        tierLabel: 'A',
        traits: {
            helmet: 'Feathered',
            shield: 'Owl',
            color: 'Gold',
            weapon: 'Spear',
            background: 'Starry Sky',
            eyes: 'Blue'
        },
        rarity: 42
    }
};

// Load report data
async function loadReport() {
    // In production, fetch from JSON file:
    // const response = await fetch('report.json');
    // const data = await response.json();
    
    const data = SAMPLE_REPORT;
    renderReport(data);
}

// Render report to DOM
function renderReport(data) {
    // Contract info
    document.getElementById('contract-file').textContent = data.contract.file;
    document.getElementById('contract-status').textContent = formatStatus(data.status);
    document.getElementById('contract-score').textContent = `${data.score}/10`;
    
    // Findings
    const findingsList = document.getElementById('findings-list');
    findingsList.innerHTML = '';
    
    data.findings.forEach(finding => {
        const findingEl = createFindingElement(finding);
        findingsList.appendChild(findingEl);
    });
    
    // Verification
    const v = data.verification;
    document.getElementById('static-status').textContent = `${v.staticAnalysis.tool}: ${v.staticAnalysis.status.toUpperCase()} (${v.staticAnalysis.findings} findings)`;
    document.getElementById('static-status').className = `status status-${v.staticAnalysis.status === 'pass' ? 'pass' : 'fail'}`;
    
    document.getElementById('poc-status').textContent = `${v.pocExecution.tool}: ${v.pocExecution.status.toUpperCase()}`;
    document.getElementById('poc-status').className = `status status-${v.pocExecution.status === 'pass' ? 'pass' : 'fail'}`;
    
    document.getElementById('fuzz-status').textContent = `${v.fuzzTesting.tool}: ${v.fuzzTesting.status.toUpperCase()} (${v.fuzzTesting.runs} runs)`;
    document.getElementById('fuzz-status').className = `status status-${v.fuzzTesting.status === 'pass' ? 'pass' : 'fail'}`;
    
    // Attestation
    if (data.attestation.uid !== '0x0000000000000000000000000000000000000000000000000000000000000000') {
        document.getElementById('eas-uid').textContent = truncateAddress(data.attestation.uid);
        const etherscanLink = document.getElementById('etherscan-link');
        etherscanLink.href = `https://sepolia.etherscan.io/tx/${data.attestation.txHash}`;
        etherscanLink.textContent = 'view';
    }
    
    // Certificate
    document.getElementById('nft-tier').textContent = `${data.certificate.tier} (${data.certificate.tierLabel})`;
    document.getElementById('nft-traits').textContent = Object.values(data.certificate.traits).join(', ');
    document.getElementById('nft-rarity').textContent = `${data.certificate.rarity}/100`;
    
    // Enable mint button if attestation exists
    const mintBtn = document.getElementById('mint-btn');
    if (data.attestation.uid && NFT_CONTRACT !== '0x0000000000000000000000000000000000000000') {
        mintBtn.disabled = false;
        mintBtn.onclick = () => mintCertificate(data.attestation.uid);
    }
}

// Create finding element
function createFindingElement(finding) {
    const div = document.createElement('div');
    div.className = 'finding';
    
    div.innerHTML = `
        <div class="finding-header">
            <span class="finding-title">FINDING #${finding.id}</span>
            <span class="finding-severity severity-${finding.severity}">${finding.severity.toUpperCase()}</span>
        </div>
        <div class="finding-meta">
            Contract: ${finding.contract} | Function: ${finding.function} | Location: ${finding.location} | Confidence: ${finding.confidence}
        </div>
        <div class="finding-description">${finding.description}</div>
        <div class="finding-actions">
            <button class="btn-small" onclick="alert('PoC code would be shown here')">View PoC</button>
            <button class="btn-small" onclick="alert('Fix diff would be shown here')">View Fix</button>
        </div>
    `;
    
    return div;
}

// Format status object
function formatStatus(status) {
    const parts = [];
    if (status.critical > 0) parts.push(`${status.critical} Critical`);
    if (status.high > 0) parts.push(`${status.high} High`);
    if (status.medium > 0) parts.push(`${status.medium} Medium`);
    if (status.low > 0) parts.push(`${status.low} Low`);
    return parts.join(' . ') || 'No findings';
}

// Truncate address for display
function truncateAddress(addr) {
    if (addr.length <= 16) return addr;
    return addr.slice(0, 10) + '...' + addr.slice(-6);
}

// Mint NFT certificate
async function mintCertificate(attestationUID) {
    if (typeof window.ethereum === 'undefined') {
        alert('Please install MetaMask to mint NFTs');
        return;
    }
    
    try {
        // Request account access
        const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
        
        // Check network
        const chainId = await window.ethereum.request({ method: 'eth_chainId' });
        if (parseInt(chainId, 16) !== SEPOLIA_CHAIN_ID) {
            alert('Please switch to Sepolia network');
            return;
        }
        
        // Call mint function
        // In production, use ethers.js to call the contract
        alert(`Minting NFT for attestation: ${attestationUID}\nAccount: ${accounts[0]}`);
        
        // TODO: Implement actual contract call
        // const provider = new ethers.providers.Web3Provider(window.ethereum);
        // const signer = provider.getSigner();
        // const contract = new ethers.Contract(NFT_CONTRACT, ABI, signer);
        // const tx = await contract.mintCertificate(accounts[0], attestationUID);
        // await tx.wait();
        
    } catch (error) {
        console.error('Mint error:', error);
        alert(`Mint failed: ${error.message}`);
    }
}

// Initialize
document.addEventListener('DOMContentLoaded', loadReport);
