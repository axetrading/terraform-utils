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
    local name; name="$3"
    local workspace_name; workspace_name="$4"
    local key; key="terraform.tfstate"

    assert_terraform_state_exists "$tfstate_bucket" "$name/$workspace_name/$key"
    
    terraform init -reconfigure \
        -backend-config="bucket=$tfstate_bucket" \
        -backend-config="dynamodb_table=$tflocks_table" \
        -backend-config="workspace_key_prefix=$name" \
        -backend-config="key=$key"
    
    terraform workspace select "$workspace_name" || terraform workspace new "$workspace_name"
}

function initialise_terraform_dev {
    local tfstate_bucket; tfstate_bucket="$1"
    local tflocks_table; tflocks_table="$2"
    local name; name="$3"
    local key; key="$name/dev.tfstate"

    assert_terraform_state_exists "$tfstate_bucket" "$key"
    
    terraform init -reconfigure \
        -backend-config="bucket=$tfstate_bucket" \
        -backend-config="dynamodb_table=$tflocks_table" \
        -backend-config="key=$key"
}
