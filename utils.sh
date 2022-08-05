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

    docker run -i $ttyopt \
        --rm -w "$PWD" -v "$PWD:$PWD" \
        -v ~/.aws:/root/.aws \
        -e TF_IN_AUTOMATION=true \
        -e TF_INPUT=0 \
        -e TF_CLI_ARGS \
        -e AWS_PROFILE -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_SESSION_TOKEN -e AWS_REGION \
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

function checkov_scan () {
    local ttyopt
    if [ -t 0 ] ; then
        ttyopt="-t"
    fi
    
    docker run -i $ttyopt \
        --rm -w "$PWD" -v "$PWD:$PWD" \
        "bridgecrew/checkov" $@
}
