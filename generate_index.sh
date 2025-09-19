#!/bin/bash
# Script to generate index.html with current server configuration

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

# Create index.html with dynamic server URL
cat > "${SCRIPT_DIR}/index.html" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>BOB Scripts</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .tab-container { margin-bottom: 20px; }
        .tab-buttons { display: flex; border-bottom: 2px solid #ddd; margin-bottom: 20px; }
        .tab-button { background: none; color: #007bff; border: none; padding: 12px 24px; cursor: pointer; font-size: 16px; border-bottom: 3px solid transparent; }
        .tab-button.active { border-bottom-color: #007bff; color: #007bff; font-weight: bold; }
        .tab-button:hover { background-color: #f8f9fa; }
        .tab-content { display: none; }
        .tab-content.active { display: block; }
        .command-box { background: #f8f9fa; padding: 16px; border-radius: 8px; margin: 15px 0; border-left: 4px solid #007bff; }
        .command-box h3 { margin: 0 0 10px 0; color: #333; }
        .command-box p { margin: 5px 0; color: #666; font-size: 14px; }
        .command-box code { background: #e9ecef; padding: 8px 12px; border-radius: 4px; display: block; margin: 10px 0; font-family: 'Courier New', monospace; word-break: break-all; }
        button { background: #007bff; color: white; border: none; padding: 8px 16px; border-radius: 4px; cursor: pointer; font-size: 14px; margin-top: 8px; }
        button:hover { background: #0056b3; }
        .warning { color: #dc3545; font-weight: bold; }
        .success { color: #28a745; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>BOB Scripts</h1>
        <p style="font-size: 20px;">Copy and paste the commands below into your terminal to run the scripts.</p>
        
        <div class="tab-container">
            <div class="tab-buttons">
                <button class="tab-button active" onclick="showTab('main')">Setup Scripts</button>
                <button class="tab-button" onclick="showTab('utils')">Undo Scripts</button>
                <button class="tab-button" onclick="showTab('downloads')">Downloads(Fallback)</button>
            </div>
            
            <div id="main" class="tab-content active">

                <div class="command-box">
                    <h3>Step 1 Install Packages</h3>
                    <p>Installs development tools and software packages.</p>
                    <p>Includes VS Code, Sublime Text, CodeBlocks, and other essential tools.</p>
                    <code id="cmd2">bash <(wget -qO- ${SERVER_URL}/installer.sh ${SERVER_IP})</code>
                    <button onclick="copyCmd('cmd2')">Copy Step 1</button>
                </div>
                <div class="command-box">
                    <h3>Step 2: Create BOB25 User</h3>
                    <p>Downloads and runs the main BOB configuration script.</p>
                    <p>Sets up the basic system environment and dependencies. </p>
                    <p>Sets password for BOB25 user to <b>allbatchtour</b>.</p>
                    <p>Changes password for student(sudo user) user. To know it ask <b>Ninad</b>.</p>
                    <code id="cmd1">bash <(wget -qO- ${SERVER_URL}/bob25.sh)</code>
                    <button onclick="copyCmd('cmd1')">Copy Step 2</button>
                </div>
                
                
                <div class="command-box">
                    <h3>Step 3: Block all sites except Toph.co (with Persistence)</h3>
                    <p>Configures firewall rules to allow access only to Toph.co domains.</p>
                    <p>Automatically sets up persistence so firewall survives reboots.</p>
                    <p class="success">✅ This single command does both firewall setup and persistence.</p>
                    <code id="cmd3">sudo wget -qO /complete-toph-firewall.sh ${SERVER_URL}/complete-toph-firewall.sh && sudo wget -qO /reset.sh ${SERVER_URL}/reset.sh && sudo chmod +x /complete-toph-firewall.sh && sudo /complete-toph-firewall.sh && sudo chmod +x /reset.sh</code>
                    <button onclick="copyCmd('cmd3')">Copy Complete Firewall Setup</button>
                </div>
            </div>
            
            <div id="utils" class="tab-content">
                <div class="command-box">
                    <h3>Undo Step 1: Reset Firewall</h3>
                    <p>Removes all firewall restrictions and restores default settings.</p>
                    <p class="warning">⚠️ Only run this if you want to remove all network restrictions.</p>
                    <code id="cmd4">sudo wget -qO /reset.sh ${SERVER_URL}/reset.sh && sudo chmod +x /reset.sh && sudo /reset.sh</code>
                    <button onclick="copyCmd('cmd4')">Copy Reset Script</button>
                </div>
                
                <div class="command-box">
                    <h3>Undo Step 2: Change Student Password</h3>
                    <p>Sets the password for 'student' user to 'student'.</p>
                    <p>Bypasses Ubuntu's password complexity requirements for easy access.</p>
                    <code id="cmd5">sudo wget -qO /cngpass.sh ${SERVER_URL}/cngpass.sh && sudo chmod +x /cngpass.sh && sudo /cngpass.sh</code>
                    <button onclick="copyCmd('cmd5')">Copy Password Script</button>
                </div>
            </div>
        </div>
        
        <div id="downloads" class="tab-content">
            <h2>Manual Downloads(Fallback)</h2>
            <div class="command-box">
                <h3>Download BOB Scripts</h3>
                <p>Download individual script files for offline use.</p>
                <p>Right-click and "Save link as" to download each script.</p>
                <ul style="list-style: none; padding: 0;">
                    <li style="margin: 8px 0;"><a href="${SERVER_URL}/bob25.sh" download style="color: #007bff; text-decoration: none;">📄 bob25.sh</a></li>
                    <li style="margin: 8px 0;"><a href="${SERVER_URL}/installer.sh" download style="color: #007bff; text-decoration: none;">📄 installer.sh</a></li>
                    <li style="margin: 8px 0;"><a href="${SERVER_URL}/complete-toph-firewall.sh" download style="color: #007bff; text-decoration: none;">📄 complete-toph-firewall.sh</a></li>
                    <li style="margin: 8px 0;"><a href="${SERVER_URL}/reset.sh" download style="color: #007bff; text-decoration: none;">📄 reset.sh</a></li>
                    <li style="margin: 8px 0;"><a href="${SERVER_URL}/cngpass.sh" download style="color: #007bff; text-decoration: none;">📄 cngpass.sh</a></li>
                </ul>
            </div>
        </div>
    </div>
    
    <script>
        // Tab functionality
        function showTab(tabName) {
            // Hide all tab contents
            const tabContents = document.querySelectorAll('.tab-content');
            tabContents.forEach(content => content.classList.remove('active'));
            
            // Remove active class from all tab buttons
            const tabButtons = document.querySelectorAll('.tab-button');
            tabButtons.forEach(button => button.classList.remove('active'));
            
            // Show selected tab content
            document.getElementById(tabName).classList.add('active');
            
            // Add active class to clicked button
            event.target.classList.add('active');
        }
        
        // Copy command functionality
        function copyCmd(cmdId) {
            const cmdElem = document.getElementById(cmdId);
            const cmd = cmdElem.textContent;
            // Find the button that triggered this function
            const btns = document.querySelectorAll('button');
            let btn = null;
            btns.forEach(b => {
                if (b.getAttribute('onclick') === \`copyCmd('\${cmdId}')\`) btn = b;
            });
            if (navigator.clipboard) {
                navigator.clipboard.writeText(cmd).then(function() {
                    showCopiedCue(btn);
                }, function() {
                    fallbackCopyTextToClipboard(cmd, btn);
                });
            } else {
                fallbackCopyTextToClipboard(cmd, btn);
            }
        }

        function showCopiedCue(btn) {
            if (!btn) return;
            const original = btn.textContent;
            btn.textContent = 'Copied!';
            btn.style.background = '#28a745';
            setTimeout(() => {
                btn.textContent = original;
                btn.style.background = '#007bff';
            }, 1200);
        }

        // Fallback for older browsers
        function fallbackCopyTextToClipboard(text, btn) {
            var textArea = document.createElement("textarea");
            textArea.value = text;
            document.body.appendChild(textArea);
            textArea.focus();
            textArea.select();
            try {
                document.execCommand('copy');
                showCopiedCue(btn);
            } catch (err) {
                if (btn) {
                    btn.textContent = 'Copy failed';
                    btn.style.background = '#dc3545';
                    setTimeout(() => {
                        const onclick = btn.getAttribute('onclick');
                        if (onclick.includes('cmd1')) btn.textContent = 'Copy Step 1';
                        else if (onclick.includes('cmd2')) btn.textContent = 'Copy Step 2';
                        else if (onclick.includes('cmd3')) btn.textContent = 'Copy Complete Firewall Setup';
                        else if (onclick.includes('cmd4')) btn.textContent = 'Copy Reset Script';
                        else if (onclick.includes('cmd5')) btn.textContent = 'Copy Password Script';
                        btn.style.background = '#007bff';
                    }, 1200);
                }
            }
            document.body.removeChild(textArea);
        }
    </script>
</body>
</html>
EOF

echo "index.html generated with server URL: ${SERVER_URL}"
