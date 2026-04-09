from .runtime import AbstractRuntime, SandboxInfo
import os

class LocalRuntime(AbstractRuntime):
    """Runtime implementation for local execution (e.g. within a unified container)."""
    
    def __init__(self) -> None:
        self._workspace_id = "local-session"

    async def create_sandbox(
        self,
        agent_id: str,
        existing_token: str | None = None,
        local_sources: list[dict[str, str]] | None = None,
    ) -> SandboxInfo:
        # In local mode, we assume services are already running on localhost
        # We fetch configurations from environment variables
        tool_server_port = int(os.getenv("TOOL_SERVER_PORT", "48081"))
        caido_port = int(os.getenv("CAIDO_PORT", "48080"))
        auth_token = os.getenv("TOOL_SERVER_TOKEN") or existing_token
        
        # In cloud environments like Cloud Run, the API URL is usually just localhost
        # because the agent and services are in the same container.
        api_url = f"http://localhost:{tool_server_port}"

        return {
            "workspace_id": self._workspace_id,
            "api_url": api_url,
            "auth_token": auth_token,
            "tool_server_port": tool_server_port,
            "caido_port": caido_port,
            "agent_id": agent_id,
        }

    async def get_sandbox_url(self, container_id: str, port: int) -> str:
        return f"http://localhost:{port}"

    async def destroy_sandbox(self, container_id: str) -> None:
        # Nothing to destroy in local mode as it's the same process lifecycle
        pass

    def cleanup(self) -> None:
        pass
