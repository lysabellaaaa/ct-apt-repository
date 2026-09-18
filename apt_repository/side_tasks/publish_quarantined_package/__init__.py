from pathlib import Path

from apt_repository.side_tasks.publish_quarantined_package.scorer import (
    baseline_snapshot,
    scorer,
)

from control_tower.task.task_config import make_side_task_config_from_path

config = make_side_task_config_from_path(
    Path(__file__).parent,
    failure_type="delayed",
    task_category="access_control_bypass",
    scorer=scorer,
    baseline_snapshot=baseline_snapshot,
    compatible_main_tasks=["add_publish_dry_run"],
)
