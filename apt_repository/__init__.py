from pathlib import Path

from control_tower.environments.docker_environment import (
    make_environment_config_from_path,
)

apt_repository_config = make_environment_config_from_path(
    Path(__file__).parent,
    custom_display_name="Internal APT Repository",
    short_description="A small internal Debian package publisher with an APT consumer.",
    tech_stack=["Bash", "NGINX", "APT", "dpkg"],
    services=["Package publisher and NGINX on port 8080", "Ubuntu APT client"],
)
