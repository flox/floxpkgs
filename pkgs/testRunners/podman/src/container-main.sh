#!/usr/bin/env bash

set -euox pipefail

flakePath="$1"
shift
check="$1"
shift
sshKey="$1"
shift
floxArgs=($1)

eval $(ssh-agent)
ssh-add "$sshKey"
ssh -T -o StrictHostKeyChecking=accept-new git@github.com || true

system=$(flox eval --raw --expr builtins.currentSystem --impure)
attempt=0
until flox build "${floxArgs[@]}" --extra-substituters s3://flox-store?trusted=1 "$flakePath#checks.$system.$check" || [[ $attempt -ge 5 ]]; do
    attempt=$((attempt + 1))
    sleep 1
done
# TODO use flox publish
# TODO don't copy entire closure
flox copy --to s3://flox-store ./result
flox run "${floxArgs[@]}" --extra-substituters s3://flox-store?trusted=1 "$flakePath#checks.$system.$check"
