# OpenClaw Agent

Privacy-focused AI agent for Android. Forked from Kimi Claw with all proprietary business references removed and BYOK (Bring Your Own Key) support added.

## Features

- **AI-powered Android automation** — accessibility service, notification listener, IME
- **Full Linux runtime** — bundled Debian via proot-distro
- **BYOK** — use any OpenAI-compatible API provider
- **Zero telemetry** — ByteDance analytics preserved for stability, no proprietary tracking

## Build

The APK is built via GitHub Actions. Download from the [Actions tab](https://github.com/Hpkings777/openclaw-agent/actions).

## Configuration

After installing, set your API key in `~/.kimi/config.toml`:

```toml
[providers.kimi-for-coding]
type = "openai-compatible"
base_url = "https://api.openai.com/v1"
api_key = "sk-your-key-here"
```

Or use any OpenAI-compatible provider by changing `base_url`.

## License

This project is a fork of Kimi Claw (com.moonshot.kimiclaw). Modifications are for educational purposes.
