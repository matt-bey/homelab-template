# AdGuard Home

Status: Operational

Host: [docker-host](../docker-host/)


If AdGuard goes down, the UDM-SE falls back to its secondary DNS (`1.1.1.1`) — clients keep resolving, just without ad-blocking/filtering/logging until AdGuard is back.
