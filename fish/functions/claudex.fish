function claudex --description 'Run Claude Code through the local Codex proxy'
    set -l key_file "$HOME/.config/cli-proxy-api/api-key"
    if not test -r "$key_file"
        echo "claudex: missing proxy API key: $key_file" >&2
        return 1
    end

    env ANTHROPIC_BASE_URL=http://127.0.0.1:8317 \
        ANTHROPIC_AUTH_TOKEN=(string trim < "$key_file") \
        CLAUDE_CODE_SUBAGENT_MODEL=gpt-5.6-sol \
        CLAUDE_CODE_ALWAYS_ENABLE_EFFORT=1 \
        CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY=3 \
        ENABLE_TOOL_SEARCH=false \
        claude --model gpt-5.6-sol $argv
end
