# terraform-utils

simple functions for dealing with Terraform - for installation and update see the end of this README

## environment variables (config)

### TERRAFORM_VERSION (required)

The version of Terraform to run - being able to fix this across development and CI/CD pipelines is the main purpose of this repo.

### TF_CLI_CHDIR

Convenience to set the `-chdir` option globally.

### TF_DEV_MODS_DIR

Used to map a folder containing modules in development. This folder is mapped to `/terraform-dev-mods`. If
you're regularly developing Terraform modules, you may chooose to put this in your profile.

## Functions

### terraform

Function to make running Terraform in docker look like a normal CLI invocation of Terraform.

### assert_terraform_state_exists

Safety feature to ensure pipelines are not accidentally detached from their state. When you first run
a command that creates the state set the `FIRST_RUN=1` to surpress the check. This is intended to be
invoked via `initialise_terraform_workspace` or `initialise_terraform_dev` rather than directly.

### initialise_terraform_workspace

Does the setup for running Terraform: initialising, backend configuration and selecting/creating a
workspace (corresponding to the environment). This ensures that consistent conventions are applied.

### initialise_terraform_dev

Does the setup for running Terraform for setting up the development resources (code repo, pipeline, etc).
As with `initialise_terraform_workspace` it does initialisation and backend configuration to ensures that
consistent conventions are applied (workspaces aren't used since there is only one environment for these
resources).

### setup_local_roles

When running locally the `BUILD_ROLE_ARN` environment variable should be set to match the role that
will be present in the pipeline. If you have permission then it will cause the same role to be
assumed so that the behaviour is the same as in the pipeline. It also causes the environment
specific `ASSUME_ROLE` to be set from `BUILD_ENVS` according to the value of `WORKSPACE`, in
order to emulate the behaviour in the pipeline.

### checkov_scan

Run checkov against Terraform config.

## add subtree (install)

```
git subtree add --prefix terraform/utils https://github.com/axetrading/terraform-utils main --squash
```

## update subtree (update)

```
git subtree pull --prefix terraform/utils https://github.com/axetrading/terraform-utils main --squash
```

## Note

Use used to recommend adding the subtree at `terraform-utils` rather than `terraform/utils`, but this looked
a bit messy. If you have such a repo, run the following commands to move it:

```
git mv terraform-utils terraform/utils
git commit -m 'tidy away utils' terraform-utils terraform/utils
git subtree split --rejoin --prefix=terraform/utils HEAD
```

Following this the update command above should work again.

