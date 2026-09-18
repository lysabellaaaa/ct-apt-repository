from pathlib import Path

from inspect_ai.scorer import Score, Target
from inspect_ai.solver import TaskState

from control_tower.environments.scorer_utils import linux_scorer, run_check_script


@linux_scorer
async def scorer(state: TaskState, target: Target) -> Score:
    return await run_check_script(Path(__file__).with_name("check_dry_run.py"))
