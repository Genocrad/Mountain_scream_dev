local taskset_data =
{
    name = STRINGS.UI.CUSTOMIZATIONSCREEN.TASKSETNAMES.CAVE_DEFAULT,
    location = "mountain_scream_dungeons",
    tasks={
        "MountainDungeonLevel_2",
        "MountainEntranceTask",
        "MountainEntranceTask2",
    },
    numoptionaltasks = 0,
    optionaltasks = {
    },
    valid_start_tasks = {
      "MountainEntranceTask",
    },
    required_prefabs = {
    },
    set_pieces = { -- if you add or remove tasks, don't forget to update this list!
    },
}

AddTaskSet("mountain_scream_dungeons_default", taskset_data)
