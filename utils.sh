function terraform () {
    if [ -z "$TERRAFORM_VERSION" ]; then
        echo TERRAFORM_VERSION must be set >&2
        return 1
    fi

    local ttyopt
    if [ -t 0 ] ; then
        ttyopt="-t"
    fi

    local tf_global_args
    if [ -n "$TF_CLI_CHDIR" ]; then
        tf_global_args="-chdir=$TF_CLI_CHDIR"
    fi

    local tf_dev_modules_folder_mapping
    if [ -n "$TF_DEV_MODS_DIR" ]; then
        echo "Mapping '$TF_DEV_MODS_DIR' (\$TF_DEV_MODS_DIR) to /terraform-dev-mods" >&2
        tf_dev_modules_folder_mapping="-v $TF_DEV_MODS_DIR:/terraform-dev-mods"
    fi

    docker run -i $ttyopt \
        --rm -w "$PWD" -v "$PWD:$PWD" \
        -v ~/.aws:/root/.aws \
        $tf_dev_modules_folder_mapping \
        -e TF_IN_AUTOMATION=true \
        -e TF_INPUT=0 \
        -e TF_CLI_ARGS \
        -e AWS_PROFILE -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_SESSION_TOKEN -e AWS_REGION \
        -e GITHUB_TOKEN \
        "hashicorp/terraform:$TERRAFORM_VERSION" $tf_global_args $@
}

function assert_terraform_state_exists () {
    local bucket
    bucket="$1"
    local key
    key="$2"
    if [ -z "$FIRST_RUN" ]; then
        aws s3api head-object --bucket "$bucket" --key "$key" >/dev/null 2>&1 || not_exist=true
        if [ $not_exist ]; then
            echo "error: no Terraform state found at s3://$bucket/$key" >&2
            echo "if this is the first run you should set the FIRST_RUN=1 environment variable" >&2
            return 1
        fi
    fi
}

function initialise_terraform_workspace {
    local tfstate_bucket; tfstate_bucket="$1"
    local tflocks_table; tflocks_table="$2"
    local repo_name; repo_name="$3"
    local workspace_name; workspace_name="$4"
    local key; key="terraform.tfstate"

    assert_terraform_state_exists "$tfstate_bucket" "$repo_name/$workspace_name/$key"
    
    terraform init -reconfigure \
        -backend-config="bucket=$tfstate_bucket" \
        -backend-config="dynamodb_table=$tflocks_table" \
        -backend-config="workspace_key_prefix=$repo_name" \
        -backend-config="key=$key"
    
    terraform workspace select "$workspace_name" || terraform workspace new "$workspace_name"
}

function initialise_terraform_dev {
    local tfstate_bucket; tfstate_bucket="$1"
    local tflocks_table; tflocks_table="$2"
    local repo_name; repo_name="$3"
    local key; key="$repo_name/dev.tfstate"

    assert_terraform_state_exists "$tfstate_bucket" "$key"
    
    terraform init -reconfigure \
        -backend-config="bucket=$tfstate_bucket" \
        -backend-config="dynamodb_table=$tflocks_table" \
        -backend-config="key=$key"
}

function checkov_scan () {
    local ttyopt
    if [ -t 0 ] ; then
        ttyopt="-t"
    fi
    
    docker run -i $ttyopt \
        --rm -w "$PWD" -v "$PWD:$PWD" \
        "bridgecrew/checkov" $@
}
