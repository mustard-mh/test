// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
const vscode = require('vscode');

// This method is called when your extension is activated
// Your extension is activated the very first time the command is executed

function activate() {
	for (let i = 0; i < 3; i++) {
		vscode.commands.executeCommand('simpleBrowser.api.open', 'https://www.google.com/');
	}
}

// This method is called when your extension is deactivated
function deactivate() { }

module.exports = {
	activate,
	deactivate
}
