# misctools
a collection of scripts used in my daily life.

## Installation

1. Clone the repository.
```sh
git clone https://github.com/honood/misctools.git
```

2. Install project dependencies
```sh
bundle install
```

3. Run script
```sh
cd <path_to_misctools>
ruby <path_of_target_script_relative_to_root_of_misctools>
```

## Descriptions of the scripts

1. `cleanup/clean_omnifocus_backups.rb`

    Delete all OmniFoucus backups except for the latest one.
    
2. `cleanup/delete_ios_simulator_devices.rb`

    Delete installed Xcode simulators in batches.
