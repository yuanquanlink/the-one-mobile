# The One Bridge Protocol 1.0

The protocol is local-first JSON over HTTP. The machine-readable contract is `protocol.json`.

## Security

- Default bind address: `127.0.0.1`.
- A non-loopback bind requires a shared secret of at least 24 characters.
- Send the secret as `x-the-one-token` on every request.
- There is no public tunnel, router change, UPnP, account session reuse, or embedded production secret.

## Retry and update rules

- Mobile-generated `id` is the idempotency key.
- Repeating the same create without `upsert` returns the existing object with `duplicate: true`.
- Reusing an ID for different content without `upsert` returns HTTP 409.
- Mobile synchronization sends `upsert: true`; this updates the existing object and never creates a second row.
- A network error does not invalidate the mobile copy. The mobile item remains retryable.

## Capability boundaries

- Task dispatch returns `dispatchMode: manual`. It is a real local queue, not an undocumented Codex API.
- Search covers Bridge Inbox/Task data and, only when explicitly configured, a bounded local knowledge root.
- Every search response returns `obsidianConnected: false`; it never claims that Obsidian or `D:\AI_Knowledge` is connected.

## Quick check

```powershell
.\tools\start-bridge.ps1
.\tools\check-bridge.ps1
```

For LAN use, supply the same session token to both scripts and the mobile Settings page.
