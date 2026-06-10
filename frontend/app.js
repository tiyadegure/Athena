// ATHENA - Frontend Application
// Loads audit report from JSON, MetaMask wallet, NFT minting

const SEPOLIA_CHAIN_ID_HEX = '0xaa36a7';
const EAS_CONTRACT = '0xC2679fBD37d54388Ce493F1DB75320D236e1815e';
const NFT_CONTRACT = '0xcaA7faeA44C3513F629C6f260ad26EBB677E5E4E'; // Redeployed to Sepolia (v5.4)

let connectedAccount = null;
let provider = null;
let signer = null;
let reportData = null;

// Fallback sample data
const SAMPLE_REPORT = {
    meta: { version: "1.0", auditor: "GLM-5.1", project: "Athena", timestamp: "2026-06-12T12:00:00Z" },
    target: {
        name: "DeFi Protocol Audit",
        contracts: [
            { file: "Token.sol", name: "Token", address: "0x3A2e...f0C1" },
            { file: "Oracle.sol", name: "Oracle", address: "0x7B4c...b7C" },
            { file: "Vault.sol", name: "Vault", address: "0x9D5e...4A3E" }
        ],
        network: "Sepolia"
    },
    summary: { total_findings: 5, critical: 1, high: 2, medium: 1, low: 1, informational: 0, score: 2 },
    findings: [
        {
            id: 1, title: "Reentrancy in Vault.withdraw()", severity: "critical", confidence: 95,
            contract: "Vault.sol", function: "withdraw()", location: "line 45-52",
            description: "Vault.withdraw() sends ETH via low-level call before updating balances. An attacker can re-enter to drain funds.",
            fix: "Use checks-effects-interactions pattern or ReentrancyGuard.",
            poc: true, poc_passed: true, poc_file: "ReentrancyExploit.t.sol"
        },
        {
            id: 2, title: "Oracle price manipulation via flash loan", severity: "high", confidence: 88,
            contract: "Oracle.sol", function: "getPrice()", location: "line 23-28",
            description: "Oracle uses spot price which can be manipulated via flash loan in a single transaction.",
            fix: "Use TWAP (Time-Weighted Average Price) oracle.",
            poc: true, poc_passed: true, poc_file: "FlashLoanExploit.t.sol"
        },
        {
            id: 3, title: "Missing access control on Vault.setOracle()", severity: "high", confidence: 92,
            contract: "Vault.sol", function: "setOracle()", location: "line 15",
            description: "setOracle() has no access control, anyone can replace the oracle address.",
            fix: "Add onlyOwner modifier.",
            poc: false, poc_passed: false
        },
        {
            id: 4, title: "Integer overflow in Token.transfer()", severity: "medium", confidence: 80,
            contract: "Token.sol", function: "transfer()", location: "line 30",
            description: "Transfer amount not checked against balance, potential overflow in Solidity < 0.8.0.",
            fix: "Use SafeMath or Solidity >= 0.8.0.",
            poc: false, poc_passed: false
        },
        {
            id: 5, title: "Uninitialized storage pointer in Vault", severity: "low", confidence: 75,
            contract: "Vault.sol", function: "_getBalance()", location: "line 60",
            description: "Storage pointer declared but not initialized, may point to slot 0.",
            fix: "Initialize storage pointer or use memory.",
            poc: false, poc_passed: false
        }
    ],
    verification: {
        static_analysis: { slither: { status: "pass", findings: 4 }, aderyn: { status: "pass", findings: 3 }, halmos: { status: "pass", properties_checked: 8 } },
        poc_execution: { tool: "Foundry", status: "pass", tests_run: 2, tests_passed: 2 },
        fuzz_testing: { tool: "Foundry", status: "pass", runs: 256 }
    },
    attack_simulation: {
        scenario: "Flash loan -> Oracle manipulation -> Vault drain",
        estimated_loss: "$2.3M",
        steps: ["Borrow 1000 Token via flash loan", "Manipulate Oracle spot price to 10x", "Deposit inflated Token into Vault", "Withdraw超额 Vault assets", "Repay flash loan, profit ~$2.3M"]
    },
    attestation: {
        uid: "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
        network: "sepolia",
        tx_hash: "0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
        url: "https://sepolia.eas.xyz/attestation/0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
    },
    certificate: {
        tier: "Gold", tier_label: "A",
        traits: { helmet: "Feathered", shield: "Owl", color: "Gold", weapon: "Spear", background: "Starry Sky", eyes: "Blue" },
        rarity: 42, combinations_total: 12000
    }
};

// ---- Init ----
document.addEventListener('DOMContentLoaded', () => {
    loadReport();
});

// ---- Load Report ----
async function loadReport() {
    try {
        // Try loading from demo/report.json (relative to frontend dir)
        const response = await fetch('../demo/report.json');
        if (!response.ok) throw new Error('Failed to load');
        reportData = await response.json();
    } catch (e) {
        console.warn('Using embedded sample data:', e.message);
        reportData = SAMPLE_REPORT;
    }
    renderAll(reportData);
}

// ---- Render All ----
function renderAll(data) {
    renderSummary(data);
    renderTarget(data);
    renderFindings(data);
    renderVerification(data);
    renderAttackSimulation(data);
    renderAttestation(data);
    renderCertificate(data);
}

// ---- Summary ----
function renderSummary(data) {
    const s = data.summary;
    const el = document.getElementById('summary-content');
    el.className = '';
    el.innerHTML = `
        <div class="summary-grid">
            <div class="summary-item">
                <div class="summary-value">${s.total_findings}</div>
                <div class="summary-label">Findings</div>
            </div>
            <div class="summary-item severity-critical-text">
                <div class="summary-value">${s.critical}</div>
                <div class="summary-label">Critical</div>
            </div>
            <div class="summary-item severity-high-text">
                <div class="summary-value">${s.high}</div>
                <div class="summary-label">High</div>
            </div>
            <div class="summary-item severity-medium-text">
                <div class="summary-value">${s.medium}</div>
                <div class="summary-label">Medium</div>
            </div>
            <div class="summary-item severity-low-text">
                <div class="summary-value">${s.low}</div>
                <div class="summary-label">Low</div>
            </div>
            <div class="summary-item">
                <div class="summary-value">${s.score}/10</div>
                <div class="summary-label">Score</div>
            </div>
        </div>
        <div class="meta-row">
            <span>Auditor: ${data.meta.auditor}</span>
            <span>Project: ${data.meta.project}</span>
            <span>${data.meta.timestamp}</span>
        </div>
    `;
}

// ---- Target ----
function renderTarget(data) {
    const t = data.target;
    const el = document.getElementById('target-content');
    el.className = '';
    let contractRows = t.contracts.map(c =>
        `<div class="target-row"><span>${c.file}</span><span>${c.name}</span><span class="mono-small">${c.address}</span></div>`
    ).join('');
    el.innerHTML = `
        <div class="target-header">${t.name} <span class="network-badge">${t.network}</span></div>
        <div class="target-list">${contractRows}</div>
    `;
}

// ---- Findings ----
function renderFindings(data) {
    const el = document.getElementById('findings-list');
    el.className = '';
    el.innerHTML = '';
    // Sort by severity
    const order = { critical: 0, high: 1, medium: 2, low: 3, informational: 4 };
    const sorted = [...data.findings].sort((a, b) => (order[a.severity] || 5) - (order[b.severity] || 5));
    sorted.forEach(f => {
        const div = document.createElement('div');
        div.className = 'finding';
        div.innerHTML = `
            <div class="finding-header">
                <span class="finding-title">FINDING #${f.id}: ${escHtml(f.title)}</span>
                <span class="finding-severity severity-${f.severity}">${f.severity.toUpperCase()}</span>
            </div>
            <div class="finding-meta">
                Contract: ${escHtml(f.contract)} | Function: ${escHtml(f.function)} | Location: ${escHtml(f.location)} | Confidence: ${f.confidence}%
            </div>
            <div class="finding-detail" id="finding-detail-${f.id}" style="display:none;">
                <div class="finding-description">${escHtml(f.description)}</div>
                <div class="finding-fix"><strong>Fix:</strong> ${escHtml(f.fix)}</div>
                ${f.poc ? `<div class="finding-poc">PoC: ${f.poc_passed ? 'PASS' : 'FAIL'} (${escHtml(f.poc_file || '')})</div>` : ''}
            </div>
            <div class="finding-actions">
                <button class="btn-small" onclick="toggleDetail(${f.id})">Details</button>
            </div>
        `;
        el.appendChild(div);
    });
}

function toggleDetail(id) {
    const el = document.getElementById('finding-detail-' + id);
    if (el) el.style.display = el.style.display === 'none' ? 'block' : 'none';
}

// ---- Verification ----
function renderVerification(data) {
    const v = data.verification;
    const el = document.getElementById('verification-content');
    el.className = '';
    el.innerHTML = `
        <div class="verification-grid">
            <div class="verification-item">
                <div class="verification-engine">Slither</div>
                <div class="verification-result ${v.static_analysis.slither.status}">${v.static_analysis.slither.status.toUpperCase()}</div>
                <div class="verification-meta">${v.static_analysis.slither.findings} findings</div>
            </div>
            <div class="verification-item">
                <div class="verification-engine">Aderyn</div>
                <div class="verification-result ${v.static_analysis.aderyn.status}">${v.static_analysis.aderyn.status.toUpperCase()}</div>
                <div class="verification-meta">${v.static_analysis.aderyn.findings} findings</div>
            </div>
            <div class="verification-item">
                <div class="verification-engine">Halmos</div>
                <div class="verification-result ${v.static_analysis.halmos.status}">${v.static_analysis.halmos.status.toUpperCase()}</div>
                <div class="verification-meta">${v.static_analysis.halmos.properties_checked} properties</div>
            </div>
            <div class="verification-item">
                <div class="verification-engine">PoC (${v.poc_execution.tool})</div>
                <div class="verification-result ${v.poc_execution.status}">${v.poc_execution.status.toUpperCase()}</div>
                <div class="verification-meta">${v.poc_execution.tests_passed}/${v.poc_execution.tests_run} passed</div>
            </div>
            <div class="verification-item">
                <div class="verification-engine">Fuzz (${v.fuzz_testing.tool})</div>
                <div class="verification-result ${v.fuzz_testing.status}">${v.fuzz_testing.status.toUpperCase()}</div>
                <div class="verification-meta">${v.fuzz_testing.runs} runs</div>
            </div>
        </div>
    `;
}

// ---- Attack Simulation ----
function renderAttackSimulation(data) {
    const a = data.attack_simulation;
    const el = document.getElementById('attack-content');
    el.className = '';
    let steps = a.steps.map((s, i) =>
        `<div class="attack-step"><span class="step-num">${i + 1}</span><span>${escHtml(s)}</span></div>`
    ).join('');
    el.innerHTML = `
        <div class="attack-header">${escHtml(a.scenario)}</div>
        <div class="attack-loss">Estimated Loss: ${escHtml(a.estimated_loss)}</div>
        <div class="attack-steps">${steps}</div>
    `;
}

// ---- Attestation ----
function renderAttestation(data) {
    const att = data.attestation;
    const el = document.getElementById('attestation-content');
    el.className = '';
    el.innerHTML = `
        <div class="attestation-grid">
            <div class="attestation-row"><span class="att-label">UID</span><span class="mono-small">${att.uid}</span></div>
            <div class="attestation-row"><span class="att-label">Network</span><span>${att.network}</span></div>
            <div class="attestation-row"><span class="att-label">TX</span><span class="mono-small">${att.tx_hash}</span></div>
            <div class="attestation-row"><span class="att-label">Link</span><a href="${escHtml(att.url)}" target="_blank" class="link">View on EAS</a></div>
        </div>
    `;
}

// ---- Certificate ----
function renderCertificate(data) {
    const cert = data.certificate;
    const el = document.getElementById('certificate-content');
    el.className = '';
    let traits = Object.entries(cert.traits).map(([k, v]) =>
        `<div class="trait-item"><span class="trait-key">${escHtml(k)}</span><span class="trait-value">${escHtml(v)}</span></div>`
    ).join('');
    el.innerHTML = `
        <div class="cert-header">
            <span class="cert-tier ${cert.tier.toLowerCase() === 's' ? 'severity-s-tier' : cert.tier.toLowerCase() === 'gold' ? 'severity-critical' : cert.tier.toLowerCase() === 'silver' ? 'severity-high' : 'severity-medium'}">${escHtml(cert.tier.toUpperCase())} (Tier ${escHtml(cert.tier_label)})</span>
            <span class="cert-rarity">Rarity: ${cert.rarity}/100</span>
        </div>
        <div class="trait-grid">${traits}</div>
        <div class="cert-meta">${cert.combinations_total} unique combinations</div>
        <div class="mint-section">
            <button id="mint-btn" onclick="mintCertificate()" disabled>Mint Certificate NFT</button>
            <div id="mint-status"></div>
        </div>
    `;
    // Enable mint if wallet connected and contract deployed
    if (connectedAccount && NFT_CONTRACT !== '0x0000000000000000000000000000000000000000') {
        document.getElementById('mint-btn').disabled = false;
    }
}

// ---- Wallet ----
async function connectWallet() {
    if (!window.ethereum) {
        alert('Please install MetaMask');
        return;
    }
    try {
        const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
        connectedAccount = accounts[0];
        provider = new ethers.providers.Web3Provider(window.ethereum);
        signer = provider.getSigner();
        await checkNetwork();
        updateWalletUI(connectedAccount);
        // Enable mint button if contract is deployed
        const mintBtn = document.getElementById('mint-btn');
        if (mintBtn && NFT_CONTRACT !== '0x0000000000000000000000000000000000000000') {
            mintBtn.disabled = false;
        }
    } catch (err) {
        console.error('Wallet connect failed:', err);
        alert('Wallet connection failed: ' + err.message);
    }
}

async function checkNetwork() {
    if (!window.ethereum) return;
    const chainId = await window.ethereum.request({ method: 'eth_chainId' });
    if (chainId !== SEPOLIA_CHAIN_ID_HEX) {
        try {
            await window.ethereum.request({
                method: 'wallet_switchEthereumChain',
                params: [{ chainId: SEPOLIA_CHAIN_ID_HEX }]
            });
        } catch (err) {
            console.error('Network switch failed:', err);
        }
    }
}

function updateWalletUI(address) {
    const addrEl = document.getElementById('wallet-address');
    const btnEl = document.getElementById('connect-btn');
    if (address) {
        addrEl.textContent = truncateAddress(address);
        btnEl.textContent = 'Connected';
        btnEl.disabled = true;
    }
}

// ---- Mint ----
const NFT_ABI = [
    "function mint(address to, uint256 tier, bytes32 attestationUID) external",
    "function balanceOf(address account, uint256 id) external view returns (uint256)"
];

async function mintCertificate() {
    if (!connectedAccount || !signer) {
        alert('Please connect your wallet first');
        return;
    }
    if (!reportData) {
        alert('Report data not loaded');
        return;
    }
    if (NFT_CONTRACT === '0x0000000000000000000000000000000000000000') {
        showMintStatus('error', 'NFT contract not deployed yet');
        return;
    }

    try {
        const tierMap = { 'S': 0, 'Gold': 1, 'Silver': 2, 'Bronze': 3 };
        const tier = tierMap[reportData.certificate.tier] ?? 3;
        const attestationUID = reportData.attestation.uid;

        const contract = new ethers.Contract(NFT_CONTRACT, NFT_ABI, signer);
        showMintStatus('pending', 'Sending transaction...');

        const tx = await contract.mint(connectedAccount, tier, attestationUID);
        showMintStatus('pending', 'TX: ' + tx.hash);

        const receipt = await tx.wait();
        showMintStatus('success', 'Minted! TX: ' + receipt.transactionHash);
    } catch (err) {
        console.error('Mint failed:', err);
        showMintStatus('error', 'Mint failed: ' + err.message);
    }
}

function showMintStatus(type, msg) {
    const el = document.getElementById('mint-status');
    if (!el) return;
    el.className = 'mint-status mint-' + type;
    el.textContent = msg;
}

// ---- Helpers ----
function truncateAddress(addr) {
    if (!addr || addr.length <= 16) return addr || '';
    return addr.slice(0, 10) + '...' + addr.slice(-6);
}

function escHtml(str) {
    if (!str) return '';
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
}
