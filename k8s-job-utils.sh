function assert_terraform_state_exists() {
    local bucket="$1"
    local key="$2"
    [ -z "$FIRST_RUN" ] || return 0
    aws s3api head-object --bucket "$bucket" --key "$key" >/dev/null 2>&1 || {
        echo "error: no Terraform state found at s3://$bucket/$key" >&2
        echo "if this is the first run you should set the FIRST_RUN=1 environment variable" >&2
        return 1
    }
}

function initialise_terraform() {
    local cmd=$1
    local tfstate_bucket="$2"
    local tflocks_table="$3"
    local repo_name="$4"
    local workspace_name="$5"
    local key="$repo_name/${workspace_name}/terraform.tfstate"

    local tf_global_args=""
    [ -z "$TF_CLI_CHDIR" ] || tf_global_args="-chdir=$TF_CLI_CHDIR"

    assert_terraform_state_exists "$tfstate_bucket" "$key"

    terraform $tf_global_args init -reconfigure \
        -backend-config="bucket=$tfstate_bucket" \
        -backend-config="dynamodb_table=$tflocks_table" \
        -backend-config="key=$key" \
        $([ "$cmd" = "workspace" ] && echo "-backend-config=workspace_key_prefix=$repo_name")

    [ "$cmd" = "workspace" ] && {
        terraform $tf_global_args workspace select "$workspace_name" || terraform $tf_global_args workspace new "$workspace_name"
    }
}


function initialise_terraform_workspace() {
    initialise_terraform "workspace" "$@"
}
