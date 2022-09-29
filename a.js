let content = 'tasks:\n'

for (let i = 0; i < 123; i++) {
    content += `  - command: LAMA_PORT=${8000+i} ./lama.sh\n`
}

require('fs').writeFileSync('./.gitpod.yml', content)