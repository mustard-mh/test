let content = 'tasks:\n'

for (let i = 0; i < 123; i++) {
    content += `  - command: SERVER_PORT=${8000+i} node server.js\n`
}

require('fs').writeFileSync('./.gitpod.yml', content)